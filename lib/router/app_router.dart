import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_feature_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/disciplinary_student_detail_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/presences_page.dart';
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
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_feature_scope.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

// Debug import — uniquement accédé via kDebugMode
import 'package:school_app_flutter/dev/component_gallery_page.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_list_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_stats_dashboard_page.dart';

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
      bootstrapHasBlockingFailure: _bootstrapBloc.state.hasBlockingFailure,
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
  final bool bootstrapHasBlockingFailure;

  const _RouterRefreshSnapshot({
    required this.authStatus,
    required this.bootstrapBlocksNavigation,
    required this.bootstrapHasBlockingFailure,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _RouterRefreshSnapshot &&
        other.authStatus == authStatus &&
        other.bootstrapBlocksNavigation == bootstrapBlocksNavigation &&
        other.bootstrapHasBlockingFailure == bootstrapHasBlockingFailure;
  }

  @override
  int get hashCode => Object.hash(
    authStatus,
    bootstrapBlocksNavigation,
    bootstrapHasBlockingFailure,
  );
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
        final hasBootstrapFailure = bootstrapState.hasBlockingFailure;
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

        // Échec du bootstrap distant : retenir sur le splash (ErrorView + retry)
        // au lieu d'éjecter vers /home sans données.
        if (hasBootstrapFailure) {
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
          builder: (context, state) => HomePage(
            initialSubMenuId: state.uri.queryParameters['subMenuId'],
          ),
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
        ShellRoute(
          builder: (context, state, child) => FinanceFeatureScope(child: child),
          routes: [
            GoRoute(
              path: AppRoutesNames.financesDashboard,
              builder: (context, state) => const FinanceStatsDashboardScope(
                child: FinanceStatsDashboardPage(),
              ),
            ),
            GoRoute(
              path: AppRoutesNames.facturations,
              builder: (context, state) => const FacturationPage(),
              routes: [
                GoRoute(
                  path: 'detail/:studentId/:academicYearId',
                  redirect: (context, state) {
                    if (!_hasRequiredPathParameters(state, const [
                      'studentId',
                      'academicYearId',
                    ])) {
                      return AppRoutesNames.facturations;
                    }
                    return null;
                  },
                  builder: (context, state) {
                    final studentId = state.pathParameters['studentId'] ?? '';
                    final academicYearId =
                        state.pathParameters['academicYearId'] ?? '';

                    final intent = FacturationDetailIntent.fromRouteContext(
                      studentId: studentId,
                      academicYearId: academicYearId,
                      extra: state.extra,
                    );

                    return FacturationDetailPage(intent: intent);
                  },
                ),
              ],
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => ClassesFeatureScope(child: child),
          routes: [
            GoRoute(
              path: AppRoutesNames.classesDashboard,
              builder: (context, state) => const ClassesStatsDashboardPage(),
            ),
            GoRoute(
              path: AppRoutesNames.organisation,
              builder: (context, state) => const ClassesOrganisationPage(),
            ),
            GoRoute(
              path: AppRoutesNames.classesList,
              builder: (context, state) => const ClassesListPage(
                intent: ClassesListIntent.classesList(),
              ),
            ),
            GoRoute(
              path: AppRoutesNames.disciplinesList,
              builder: (context, state) => const ClassesListPage(
                intent: ClassesListIntent.disciplinesList(),
              ),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AttendanceFeatureScope(child: child),
          routes: [
            GoRoute(
              path: AppRoutesNames.presences,
              builder: (context, state) => const PresencesPage(),
            ),
            GoRoute(
              path: AppRoutesNames.disciplinaryStudentDetail,
              redirect: (context, state) {
                final studentId = state.pathParameters['studentId'] ?? '';
                final academicYearId =
                    state.pathParameters['academicYearId'] ?? '';

                if (studentId.trim().isEmpty || academicYearId.trim().isEmpty) {
                  return AppRoutesNames.presences;
                }

                return null;
              },
              builder: (context, state) {
                final studentId = state.pathParameters['studentId'] ?? '';
                final academicYearId =
                    state.pathParameters['academicYearId'] ?? '';

                final intent = DisciplinaryStudentDetailIntent.fromRouteContext(
                  studentId: studentId,
                  academicYearId: academicYearId,
                  extra: state.extra,
                );

                return DisciplinaryStudentDetailPage(intent: intent);
              },
            ),
          ],
        ),
        // -------------------------------------------------------------------
        // Route debug — galerie de composants (kDebugMode uniquement)
        // -------------------------------------------------------------------
        if (kDebugMode)
          GoRoute(
            path: AppRoutesNames.componentGallery,
            name: AppRoutesNames.componentGallery,
            builder: (context, state) => const ComponentGalleryPage(),
          ),
      ],
    );
  }

  static bool _hasRequiredPathParameters(
    GoRouterState state,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = state.pathParameters[key] ?? '';
      if (value.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }
}
