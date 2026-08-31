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
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_history_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_catalog_page.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_feature_scope.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_feature_scope.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_page.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_settings_page.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

// Debug import — uniquement accédé via kDebugMode
import 'package:school_app_flutter/dev/component_gallery_page.dart';
import 'package:school_app_flutter/dev/ticket_print_bench_page.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_list_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_stats_dashboard_page.dart';

class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  final AcademicYearContextBloc _academicYearContextBloc;
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<AcademicYearContextState>
  _academicYearContextSubscription;
  late _RouterRefreshSnapshot _snapshot;

  RouterNotifier(this._authBloc, this._academicYearContextBloc) {
    _snapshot = _currentSnapshot();
    _authSubscription = _authBloc.stream.listen((_) => _notifyIfNeeded());
    _academicYearContextSubscription = _academicYearContextBloc.stream.listen(
      (_) => _notifyIfNeeded(),
    );
  }

  _RouterRefreshSnapshot _currentSnapshot() {
    return _RouterRefreshSnapshot(
      authStatus: _authBloc.state.status,
      // Signature de l'ensemble effectif : un refresh peut retirer un droit en
      // arrière-plan (ADR-014 §4). Sans elle, le routeur ne rejouerait pas son
      // `redirect` et laisserait ouverte une route devenue interdite —
      // exactement le trou que la garde ci-dessous existe pour fermer.
      permissionsSignature: _permissionsSignature(_authBloc.state.permissions),
      academicYearBlocksNavigation:
          _academicYearContextBloc.state.blocksNavigation,
      academicYearHasBlockingFailure:
          _academicYearContextBloc.state.hasBlockingFailure,
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
    _academicYearContextSubscription.cancel();
    super.dispose();
  }
}

/// Signature stable de l'ensemble effectif — triée, car l'ordre du serveur n'a
/// aucun sens métier et une simple permutation ne doit pas passer pour un
/// changement de droits.
String _permissionsSignature(List<String>? permissions) {
  // Sentinelle distincte de l'ensemble vide : « inconnu » et « aucun droit »
  // ferment tous deux les routes, mais passer de l'un à l'autre change l'écran
  // affiché — le routeur doit donc rejouer son redirect.
  if (permissions == null) return '\u0001inconnu';
  final sorted = [...permissions]..sort();
  return sorted.join('\u0000');
}

class _RouterRefreshSnapshot {
  final AuthStatus authStatus;
  final bool academicYearBlocksNavigation;
  final bool academicYearHasBlockingFailure;
  final String permissionsSignature;

  const _RouterRefreshSnapshot({
    required this.authStatus,
    required this.academicYearBlocksNavigation,
    required this.academicYearHasBlockingFailure,
    required this.permissionsSignature,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _RouterRefreshSnapshot &&
        other.authStatus == authStatus &&
        other.academicYearBlocksNavigation == academicYearBlocksNavigation &&
        other.academicYearHasBlockingFailure ==
            academicYearHasBlockingFailure &&
        other.permissionsSignature == permissionsSignature;
  }

  @override
  int get hashCode => Object.hash(
    authStatus,
    academicYearBlocksNavigation,
    academicYearHasBlockingFailure,
    permissionsSignature,
  );
}

class AppRouter {
  const AppRouter._();

  static GoRouter createRouter(
    AuthBloc authBloc,
    AcademicYearContextBloc academicYearContextBloc,
  ) {
    final notifier = RouterNotifier(authBloc, academicYearContextBloc);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: notifier,
      redirect: (context, state) => resolveRedirect(
        authStatus: authBloc.state.status,
        permissions: authBloc.state.permissions,
        academicYearBlocksNavigation:
            academicYearContextBloc.state.blocksNavigation,
        academicYearHasBlockingFailure:
            academicYearContextBloc.state.hasBlockingFailure,
        matchedLocation: state.matchedLocation,
        location: state.uri,
      ),
      routes: buildRoutes(),
    );
  }

  /// Décision de redirection, **extraite de [createRouter]** pour être
  /// éprouvable par un test.
  ///
  /// Elle ne prend que des valeurs : sans cela, la seule façon de la vérifier
  /// serait de monter un routeur complet avec ses blocs, et l'ordre des gardes —
  /// qui est tout ce qui compte ici — resterait invérifiable.
  ///
  /// Rend `null` pour « laisser passer », ou le chemin vers lequel dérouter.
  static String? resolveRedirect({
    required AuthStatus authStatus,
    required List<String>? permissions,
    required bool academicYearBlocksNavigation,
    required bool academicYearHasBlockingFailure,
    required String matchedLocation,
    required Uri location,
  }) {
    final isAuthenticated = authStatus == AuthStatus.authenticated;
    final isAuthLoading =
        authStatus == AuthStatus.loading || authStatus == AuthStatus.initial;
    final isOnSplash = matchedLocation == '/splash';
    final isOnAuthFlow =
        matchedLocation == '/login' ||
        matchedLocation.startsWith('/forgot-password');
    final isOnConfiguration = matchedLocation.startsWith(
      AppRoutesNames.configurationPath,
    );

    if (isAuthLoading) {
      return isOnSplash ? null : '/splash';
    }

    if (!isAuthenticated) {
      return isOnAuthFlow ? null : '/login';
    }

    // ── La porte de l'assistant de mise en service ──────────────────────────
    // Les deux gardes qui suivent retiennent sur le splash tant qu'il n'y a pas
    // d'année académique. Or une école qu'on n'a pas encore paramétrée n'en a
    // pas — c'est sa définition. Sans cette exception, le module Configuration
    // serait inatteignable exactement dans la seule situation pour laquelle il
    // existe, et l'agent n'aurait devant lui qu'une erreur qu'aucun
    // « Réessayer » ne peut lever.
    //
    // La permission est confrontée ICI et pas seulement en fin de fonction : les
    // deux `return` suivants la court-circuitent. Sans elle, la porte s'ouvrirait
    // pour tout le monde dès qu'une école tombe en panne de référentiel — y
    // compris à qui n'a rien à y paramétrer.
    if ((academicYearBlocksNavigation || academicYearHasBlockingFailure) &&
        isOnConfiguration) {
      return canAccessLocation(location, permissions) ? null : '/splash';
    }

    if (academicYearBlocksNavigation) {
      return isOnSplash ? null : '/splash';
    }

    // Échec de la résolution du contexte académique : retenir sur le splash
    // (ErrorView + retry) au lieu d'éjecter vers /home sans données.
    if (academicYearHasBlockingFailure) {
      return isOnSplash ? null : '/splash';
    }

    if (isOnAuthFlow || isOnSplash) return '/home';

    // Garde de permission (ADR-014 §2.9) : masquer une tuile ne suffit pas. Un
    // lien profond, une restauration d'état ou un retour arrière atteignent la
    // route sans passer par le menu — c'est précisément ce que le filtrage du
    // registre ne couvre pas.
    return canAccessLocation(location, permissions) ? null : '/home';
  }

  /// Arbre de routes de l'application, **extrait de [createRouter]** pour être
  /// parcourable par un test.
  ///
  /// La garde de permission (§2.9) ne s'applique qu'aux chemins dont le second
  /// segment est un sous-menu déclaré, ou dont le premier figure dans
  /// `kStandaloneRouteAccess`. C'est une propriété du couple routeur/registre,
  /// pas d'une route en particulier — et elle ne se vérifie qu'en énumérant les
  /// routes réellement déclarées. Un test l'exige donc ici, plutôt que de figer
  /// la correction ponctuelle d'un trou déjà trouvé.
  static List<RouteBase> buildRoutes() => [
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
      path: AppRoutesNames.configurationPath,
      name: AppRoutesNames.configuration,
      builder: (context, state) => const ConfigurationPage(),
      routes: [
        GoRoute(
          // `settings` est un chemin RELATIF : déclaré en absolu sous ce parent,
          // GoRouter refuserait l'arbre. Il hérite donc de la garde de son
          // premier segment, `configuration`.
          path: 'settings',
          name: AppRoutesNames.configurationSettings,
          builder: (context, state) => const ConfigurationSettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/home',
      name: AppRoutesNames.home,
      builder: (context, state) =>
          HomePage(initialSubMenuId: state.uri.queryParameters['subMenuId']),
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
          path: '${EnrollmentConstants.enrollmentDetailRoute}/:enrollmentId',
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
              routes: [
                // Encaissement : écran plein empilé SUR la fiche (`push`), qui
                // rend `true` au succès pour que la fiche resynchronise ses
                // listes. La garde de paramètres de la fiche s'applique aussi
                // ici — les redirects de la pile matchée sont tous joués.
                GoRoute(
                  path: 'encaissement',
                  builder: (context, state) {
                    final studentId = state.pathParameters['studentId'] ?? '';
                    final academicYearId =
                        state.pathParameters['academicYearId'] ?? '';

                    final intent =
                        FacturationCreatePaymentIntent.fromRouteContext(
                          studentId: studentId,
                          academicYearId: academicYearId,
                          extra: state.extra,
                        );

                    return FacturationCreatePaymentPage(intent: intent);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutesNames.feeControl,
          builder: (context, state) => const FeeControlPage(),
        ),
      ],
    ),
    // La caisse boutique a son propre menu, et **aucun** `FeatureScope` partagé
    // avec Finances : elle ne lit ni créance ni paiement, et l'isolation stricte
    // du module (I-4) commencerait à se défaire par le partage d'un scope.
    GoRoute(
      path: AppRoutesNames.boutiqueAchats,
      builder: (context, state) => const BoutiquePage(),
    ),
    GoRoute(
      path: AppRoutesNames.boutiqueHistorique,
      builder: (context, state) => const BoutiqueHistoryPage(),
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
          builder: (context, state) =>
              const ClassesListPage(intent: ClassesListIntent.classesList()),
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
      builder: (context, state, child) => AttendanceFeatureScope(child: child),
      routes: [
        GoRoute(
          path: AppRoutesNames.presences,
          builder: (context, state) => const PresencesPage(),
        ),
        GoRoute(
          path: AppRoutesNames.disciplinaryStudentDetail,
          redirect: (context, state) {
            final studentId = state.pathParameters['studentId'] ?? '';
            final academicYearId = state.pathParameters['academicYearId'] ?? '';

            if (studentId.trim().isEmpty || academicYearId.trim().isEmpty) {
              return AppRoutesNames.presences;
            }

            return null;
          },
          builder: (context, state) {
            final studentId = state.pathParameters['studentId'] ?? '';
            final academicYearId = state.pathParameters['academicYearId'] ?? '';

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
    ShellRoute(
      builder: (context, state, child) => DocumentsFeatureScope(child: child),
      routes: [
        GoRoute(
          path: AppRoutesNames.documentsStudents,
          builder: (context, state) => const DocumentsPage(),
          routes: [
            GoRoute(
              path: 'catalogue/:studentId/:academicYearId',
              redirect: (context, state) {
                if (!_hasRequiredPathParameters(state, const [
                  'studentId',
                  'academicYearId',
                ])) {
                  return AppRoutesNames.documentsStudents;
                }
                return null;
              },
              builder: (context, state) {
                final intent = DocumentsCatalogIntent.fromRouteContext(
                  studentId: state.pathParameters['studentId'] ?? '',
                  academicYearId: state.pathParameters['academicYearId'] ?? '',
                  extra: state.extra,
                );

                return DocumentsCatalogPage(intent: intent);
              },
            ),
          ],
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
    // -------------------------------------------------------------------
    // Route debug — banc de calage thermique (kDebugMode uniquement)
    // -------------------------------------------------------------------
    if (kDebugMode)
      GoRoute(
        path: AppRoutesNames.ticketPrintBench,
        name: AppRoutesNames.ticketPrintBench,
        builder: (context, state) => const TicketPrintBenchPage(),
      ),
  ];

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
