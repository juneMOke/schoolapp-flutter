import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
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
    _router = AppRouter.createRouter(_authBloc, _bootstrapBloc);
  }

  @override
  void dispose() {
    _bootstrapBloc.close();
    _forgotPasswordBloc.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<BootstrapBloc>.value(value: _bootstrapBloc),
        BlocProvider<ForgotPasswordBloc>.value(value: _forgotPasswordBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
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
          title: 'SchoolApp',
          theme: AppTheme.light,
          routerConfig: _router,
          // Bandeau hors-ligne global au-dessus de toutes les routes.
          builder: (context, child) =>
              BootstrapOfflineBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
