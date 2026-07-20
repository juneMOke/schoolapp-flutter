import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/web/splash_loader.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/widgets/bootstrap_offline_banner.dart';
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
  late final BootstrapBloc _bootstrapBloc;
  late final ForgotPasswordBloc _forgotPasswordBloc;
  late final SyncStatusCubit _syncStatusCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _bootstrapBloc = getIt<BootstrapBloc>()
      ..add(
        const BootstrapLocalRequested(key: AppConstants.bootstrapPayloadKey),
      );
    _forgotPasswordBloc = getIt<ForgotPasswordBloc>();
    // Cubit global de synchro : instance unique app-lifetime, fournie à tout
    // l'arbre via `.value` (top bar + écrans write-path la lisent par contexte).
    _syncStatusCubit = getIt<SyncStatusCubit>();
    _router = AppRouter.createRouter(_authBloc, _bootstrapBloc);
  }

  @override
  void dispose() {
    _bootstrapBloc.close();
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
        BlocProvider<BootstrapBloc>.value(value: _bootstrapBloc),
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
                // Login OFFLINE (ADR-010 D-01/D-02) : pas de réseau → ne pas
                // déclencher le bootstrap distant (il échouerait et bloquerait
                // la navigation). Mais il faut RECHARGER le cache local : après
                // un logout, BootstrapResetRequested a remis l'état à initial
                // (bootstrap == null) et personne d'autre ne le repeuple →
                // `blocksNavigation` resterait vrai → splash (spinner) infini.
                // Le cache Hive, lui, survit au logout (piège #2 bootstrap).
                if (state.isOffline) {
                  _bootstrapBloc.add(
                    const BootstrapLocalRequested(
                      key: AppConstants.bootstrapPayloadKey,
                    ),
                  );
                  return;
                }
                _bootstrapBloc.add(const BootstrapRemoteCurrentYearRequested());
                _bootstrapBloc.add(
                  const BootstrapRemotePreviousYearRequested(),
                );
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                _bootstrapBloc.add(const BootstrapResetRequested());
              }
            },
          ),
          // Session rejetée côté serveur (401/403) pendant le bootstrap distant
          // → logout. Le couplage bootstrap→auth passe par main.dart (sens
          // unique, comme auth→bootstrap).
          BlocListener<BootstrapBloc, BootstrapState>(
            listenWhen: (previous, current) =>
                !previous.sessionExpired && current.sessionExpired,
            listener: (context, state) =>
                _authBloc.add(const AuthLogoutRequested()),
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
          // Bandeaux globaux au-dessus de toutes les routes : dégradation de
          // session offline (ADR-010 D-08) puis « données en cache ».
          builder: (context, child) => SessionDegradationBanner(
            child: BootstrapOfflineBanner(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
