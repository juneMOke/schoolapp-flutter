import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/reset_password_page.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';

class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _subscription;

  RouterNotifier(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  const AppRouter._();

  static GoRouter createRouter(AuthBloc authBloc) {
    final notifier = RouterNotifier(authBloc);

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: notifier,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isLoading =
            authState.status == AuthStatus.loading ||
            authState.status == AuthStatus.initial;
        final isOnAuthFlow =
            state.matchedLocation == '/login' ||
            state.matchedLocation.startsWith('/forgot-password');

        if (isLoading) return null;

        if (!isAuthenticated && !isOnAuthFlow) return '/login';
        if (isAuthenticated && isOnAuthFlow) return '/home';

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: AppRoutesNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoutesNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/forgot-password/email',
          name: AppRoutesNames.forgotPasswordEmail,
          builder: (context, state) => const ForgotPasswordEmailPage(),
        ),
        GoRoute(
          path: '/forgot-password/otp',
          name: AppRoutesNames.forgotPasswordOtp,
          builder: (context, state) => const ForgotPasswordOtpPage(),
        ),
        GoRoute(
          path: '/forgot-password/reset',
          name: AppRoutesNames.forgotPasswordReset,
          builder: (context, state) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/home',
          name: AppRoutesNames.home,
          builder: (context, state) => const HomePage(),
        ),
      ],
    );
  }
}
