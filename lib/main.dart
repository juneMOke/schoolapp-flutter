import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/web/splash_loader.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_degradation_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
  // Web : retirer le pré-splash HTML une fois le 1er frame Flutter peint
  // (évite le trou bleu entre l'attache de la vue et le premier rendu).
  WidgetsBinding.instance.addPostFrameCallback((_) => removeWebSplashLoader());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ForgotPasswordBloc _forgotPasswordBloc;
  late final SyncStatusCubit _syncStatusCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    // Contrairement à l'ex-bootstrap (lecture Hive spéculative avant même
    // l'auth), la résolution ne peut démarrer qu'une fois le schoolId connu
    // (`CurrentUserContext`, posé par l'auth) : rien à déclencher ici, le
    // redirect du router reste de toute façon bloqué sur `isAuthLoading`
    // jusqu'à la transition `authenticated` ci-dessous.
    _academicYearContextBloc = getIt<AcademicYearContextBloc>();
    _forgotPasswordBloc = getIt<ForgotPasswordBloc>();
    // Cubit global de synchro : instance unique app-lifetime, fournie à tout
    // l'arbre via `.value` (top bar + écrans write-path la lisent par contexte).
    _syncStatusCubit = getIt<SyncStatusCubit>();
    _router = AppRouter.createRouter(_authBloc, _academicYearContextBloc);
  }

  @override
  void dispose() {
    _academicYearContextBloc.close();
    _forgotPasswordBloc.close();
    _authBloc.close();
    _syncStatusCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ForgotPasswordBloc>.value(value: _forgotPasswordBloc),
        BlocProvider<SyncStatusCubit>.value(value: _syncStatusCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                // Un seul événement, en ligne comme hors-ligne (ADR-010
                // D-01/D-02) : le repository lit d'abord le référentiel local
                // et ne tente un pull réseau que s'il est absent — jamais de
                // fetch distant voué à l'échec en offline.
                _academicYearContextBloc.add(
                  const AcademicYearContextRequested(),
                );
                // Jetons frais ou repli offline : dans les deux cas, pousse
                // l'outbox en attente et recalcule la pastille de synchro
                // (D-05, réconciliation silencieuse au retour réseau si
                // offline).
                _syncStatusCubit.notifyLocalWrite();
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                _academicYearContextBloc.add(
                  const AcademicYearContextResetRequested(),
                );
              }
            },
          ),
          // Session rejetée côté serveur (401/403) pendant le pull référentiel
          // → logout. Le couplage contexte académique→auth passe par
          // main.dart (sens unique, comme auth→contexte académique).
          BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
            listenWhen: (previous, current) =>
                !previous.sessionExpired && current.sessionExpired,
            listener: (context, state) =>
                _authBloc.add(const AuthLogoutRequested()),
          ),
          // Retour réseau après une période hors-ligne : re-résout le contexte
          // académique (le référentiel a pu changer pendant la coupure — le
          // PullCoordinator le rafraîchit déjà en local, mais l'instance
          // globale de ce Bloc ne le relirait pas d'elle-même).
          BlocListener<SyncStatusCubit, SyncStatusState>(
            listenWhen: (previous, current) =>
                previous.status == SyncStatus.offline &&
                current.status != SyncStatus.offline,
            listener: (context, state) {
              _academicYearContextBloc.add(
                const AcademicYearContextRequested(),
              );
            },
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          title: 'ETEELO CONNECT',
          theme: AppTheme.light,
          routerConfig: _router,
          // Bandeau global au-dessus de toutes les routes : dégradation de
          // session offline (ADR-010 D-08). Le bandeau « données en cache »
          // de l'ex-bootstrap est retiré (plus de distinction local/distant
          // séparée à ce niveau) — le statut réseau global reste signalé par
          // le `SyncIndicator` de la top bar.
          builder: (context, child) =>
              SessionDegradationBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
