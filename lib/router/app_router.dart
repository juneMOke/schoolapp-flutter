import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/reset_password_page.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';

class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  final BootstrapBloc _bootstrapBloc;
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<BootstrapState> _bootstrapSubscription;

  RouterNotifier(this._authBloc, this._bootstrapBloc) {
    _authSubscription = _authBloc.stream.listen((_) => notifyListeners());
    _bootstrapSubscription = _bootstrapBloc.stream.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _bootstrapSubscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  const AppRouter._();

  static GoRouter createRouter(AuthBloc authBloc, BootstrapBloc bootstrapBloc) {
    final notifier = RouterNotifier(authBloc, bootstrapBloc);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: notifier,
      redirect: (context, state) {
        final authState = authBloc.state;
        final bootstrapState = bootstrapBloc.state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isAuthLoading =
            authState.status == AuthStatus.loading ||
            authState.status == AuthStatus.initial;
        final isBootstrapLoading =
            bootstrapState.status == BootstrapLoadStatus.loading;
        final isOnSplash = state.matchedLocation == '/splash';
        final isOnAuthFlow =
            state.matchedLocation == '/login' ||
            state.matchedLocation.startsWith('/forgot-password');

        if (isAuthLoading) {
          return isOnSplash ? null : '/splash';
        }

        if (!isAuthenticated) {
          return isOnAuthFlow ? null : '/login';
        }

        if (isBootstrapLoading) {
          return isOnSplash ? null : '/splash';
        }

        if (isOnAuthFlow || isOnSplash) return '/home';

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
        ShellRoute(
          builder: (context, state, child) {
            return EnrollmentFeatureScope(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutesNames.preInscriptions,
              builder: (context, state) => const PreRegistrationsPage(),
            ),
            GoRoute(
              path:
                  '${EnrollmentConstants.enrollmentDetailRoute}/:enrollmentId',
              builder: (context, state) {
                final enrollmentId = state.pathParameters['enrollmentId']!;
                return EnrollmentDetailPage(enrollmentId: enrollmentId);
              },
            ),
          ],
        ),
      ],
    );
  }
}
