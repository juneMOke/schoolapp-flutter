import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/reset_password_page.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  final BootstrapBloc _bootstrapBloc;
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<BootstrapState> _bootstrapSubscription;
  late _RouterRefreshSnapshot _snapshot;

  RouterNotifier(this._authBloc, this._bootstrapBloc) {
    _snapshot = _currentSnapshot();
    _authSubscription = _authBloc.stream.listen((_) => _notifyIfNeeded());
    _bootstrapSubscription = _bootstrapBloc.stream.listen(
      (_) => _notifyIfNeeded(),
    );
  }

  _RouterRefreshSnapshot _currentSnapshot() {
    return _RouterRefreshSnapshot(
      authStatus: _authBloc.state.status,
      bootstrapBlocksNavigation: _bootstrapBloc.state.blocksNavigation,
    );
  }

  void _notifyIfNeeded() {
    final nextSnapshot = _currentSnapshot();
    if (nextSnapshot == _snapshot) {
      return;
    }

    _snapshot = nextSnapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _bootstrapSubscription.cancel();
    super.dispose();
  }
}

class _RouterRefreshSnapshot {
  final AuthStatus authStatus;
  final bool bootstrapBlocksNavigation;

  const _RouterRefreshSnapshot({
    required this.authStatus,
    required this.bootstrapBlocksNavigation,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _RouterRefreshSnapshot &&
        other.authStatus == authStatus &&
        other.bootstrapBlocksNavigation == bootstrapBlocksNavigation;
  }

  @override
  int get hashCode => Object.hash(authStatus, bootstrapBlocksNavigation);
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
        final isBootstrapBlocking = bootstrapState.blocksNavigation;
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

        if (isBootstrapBlocking) {
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
              path: AppRoutesNames.premiereInscription,
              builder: (context, state) => const FirstRegistrationPage(),
            ),
            GoRoute(
              path:
                  '${EnrollmentConstants.enrollmentDetailRoute}/:enrollmentId',
              builder: (context, state) {
                final enrollmentId = state.pathParameters['enrollmentId']!;
                final intent = EnrollmentDetailIntent.fromRouteContext(
                  enrollmentId: enrollmentId,
                  queryParameters: state.uri.queryParameters,
                  extra: state.extra,
                );

                return EnrollmentDetailPage(intent: intent);
              },
            ),
          ],
        ),
      ],
    );
  }
}
