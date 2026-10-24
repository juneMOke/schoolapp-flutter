import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_feature_scope.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/reset_password_page.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_dashboard_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_page.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcement_templates_page.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcements_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_dashboard_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_feature_scope.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_queue_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_register_page.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_dashboard_page.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_personnel_file_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_dashboard_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_register_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_attendance_page.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_file_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_detail_page.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_feature_scope.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_feature_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/recouvrement_dashboard_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_feature_scope.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_page.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_settings_page.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/features/splash/presentation/pages/splash_page.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

// Debug import — uniquement accédé via kDebugMode
import 'package:school_app_flutter/dev/component_gallery_page.dart';
import 'package:school_app_flutter/dev/ticket_print_bench_page.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_list_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_stats_dashboard_page.dart';
import 'package:school_app_flutter/router/return_location.dart';
import 'package:school_app_flutter/router/router_extra_codec.dart';
import 'package:school_app_flutter/router/hr_agent_routes.dart';
import 'package:school_app_flutter/router/student_record_routes.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/pages/class_presence_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/pages/justification_queue_page.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_capture_support.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_page.dart';

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
    RouteExitGuard.duringRouterRefresh(notifyListeners);
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
    // Vrai jusqu'à la première session ouverte de ce lancement : seule
    // l'adresse d'ouverture (F5, favori, lien collé) mérite d'être rendue. Une
    // déconnexion passe elle aussi par `loading` — sans ce verrou, l'agent
    // suivant hériterait de la page du précédent.
    var isColdStart = true;

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: notifier,
      // Sans lui, chaque rafraîchissement du routeur reconstruit les pages
      // empilées SANS leur `extra` (cf. [InMemoryExtraCodec]).
      extraCodec: InMemoryExtraCodec(),
      redirect: (context, state) {
        final redirect = resolveRedirect(
          authStatus: authBloc.state.status,
          permissions: authBloc.state.permissions,
          academicYearBlocksNavigation:
              academicYearContextBloc.state.blocksNavigation,
          academicYearHasBlockingFailure:
              academicYearContextBloc.state.hasBlockingFailure,
          matchedLocation: state.matchedLocation,
          location: state.uri,
          isColdStart: isColdStart,
        );
        if (authBloc.state.status == AuthStatus.authenticated) {
          isColdStart = false;
        }
        return redirect;
      },
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
    bool isColdStart = false,
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

    // L'adresse demandée au démarrage (F5, favori, lien collé) : déjà en
    // attente si l'on est sur le parcours d'entrée, sinon — au démarrage
    // seulement, cf. [isColdStart] — l'adresse courante elle-même.
    // Cf. `return_location.dart`.
    final pendingReturn = isOnSplash || isOnAuthFlow
        ? pendingReturnLocation(location)
        : isColdStart
        ? sanitizeReturnLocation(location.toString())
        : null;

    if (isAuthLoading) {
      return isOnSplash ? null : withReturnLocation('/splash', pendingReturn);
    }

    if (!isAuthenticated) {
      if (isOnAuthFlow) return null;
      // Session expirée au rechargement : la connexion hérite de l'adresse.
      return withReturnLocation('/login', pendingReturn);
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

    // Retenir sur le splash garde l'adresse en attente seulement si l'on vient
    // du parcours d'entrée : un contexte qui se recharge en pleine session
    // (changement d'école) ne doit pas ramener sur une page de l'école d'avant.
    final splashHold = withReturnLocation(
      '/splash',
      isOnAuthFlow || isColdStart ? pendingReturn : null,
    );

    if (academicYearBlocksNavigation) {
      return isOnSplash ? null : splashHold;
    }

    // Échec de la résolution du contexte académique : retenir sur le splash
    // (ErrorView + retry) au lieu d'éjecter vers /home sans données.
    if (academicYearHasBlockingFailure) {
      return isOnSplash ? null : splashHold;
    }

    if (isOnAuthFlow || isOnSplash) {
      // La garde de permission s'applique à l'adresse rendue comme à toute
      // autre : un lien profond ne contourne pas ADR-014 §2.9.
      final target = pendingReturn;
      return target != null && canAccessLocation(Uri.parse(target), permissions)
          ? target
          : '/home';
    }

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
      path: AppRoutesNames.photoSessionPath,
      name: AppRoutesNames.photoSession,
      // Sans prise de vue possible (navigateur), l'adresse tapée ou un favori
      // ne mènent pas à une séance qui échouerait à chaque photo.
      redirect: (context, state) =>
          photoCaptureSupported ? null : AppRoutesNames.homePath,
      builder: (context, state) => const PhotoSessionPage(),
    ),
    // La coquille : `/home` (Accueil) et `/home/{sousMenu}` (chaque écran du
    // menu). Les deux routes rendent la MÊME page — même clé — : passer de
    // l'une à l'autre met la coquille à jour au lieu d'en empiler une
    // seconde, et son état (menu ouvert, saisie en cours) survit. C'est ce
    // qui donne à chaque écran son adresse : Précédent / Suivant du
    // navigateur, F5 et lien partagé y mènent.
    //
    // Précédent y change d'écran sans changer de page : une fiche poussée
    // par-dessus (agent, contrat) resterait affichée, et l'écran quitté
    // perdrait sa saisie. `onExit` consulte leurs gardes, et referme la fiche
    // si l'on part.
    GoRoute(
      path: AppRoutesNames.homePath,
      onExit: RouteExitGuard.onExitOfPage(_shellPageKey),
      name: AppRoutesNames.home,
      // Ancienne forme `?subMenuId=` : ramenée à l'adresse canonique.
      redirect: (context, state) {
        final subMenuId = state.uri.queryParameters['subMenuId']?.trim();
        if (subMenuId == null || subMenuId.isEmpty) return null;
        return AppRoutesNames.homeSubMenuPath(subMenuId);
      },
      pageBuilder: (context, state) => _shellPage(null),
    ),
    GoRoute(
      path: AppRoutesNames.homeSubMenuRoute,
      name: AppRoutesNames.homeSubMenu,
      onExit: RouteExitGuard.onExitOfPage(_shellPageKey),
      pageBuilder: (context, state) =>
          _shellPage(state.pathParameters['subMenuId']),
      routes: [HrAgentRoutes.agent()],
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
          // Précédent du navigateur : même question que le retour système.
          onExit: RouteExitGuard.onExit,
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
          // Hors de la coquille, l'écran porte sa propre barre, avec le retour.
          builder: (context, state) => const FacturationPage.fromRoute(),
          routes: [StudentRecordRoutes.facturationDetail()],
        ),
      ],
    ),
    // Le contrôle des frais a son propre menu et son propre scope : il ne
    // partage plus celui de Finances. Les deux hydratent les mêmes caches, mais
    // le contrôle n'a que faire de l'`EnrollmentLocalListBloc` que Finances
    // fournit — il interroge le local par son propre bloc.
    ShellRoute(
      builder: (context, state, child) => FeeControlFeatureScope(child: child),
      routes: [
        GoRoute(
          path: AppRoutesNames.recouvrementDashboard,
          builder: (context, state) => const RecouvrementDashboardPage(),
        ),
        GoRoute(
          path: AppRoutesNames.recouvrementControl,
          // `extra` porte les critères quand l'écran est ouvert depuis le
          // tableau de bord ; vide, l'écran s'ouvre vierge comme par le menu.
          // Hors de la coquille, l'écran porte sa propre barre, avec le retour.
          builder: (context, state) =>
              FeeControlPage.fromRoute(state.extra, state.uri.queryParameters),
        ),
      ],
    ),
    // La caisse boutique a son propre menu, et **aucun** `FeatureScope` partagé
    // avec Finances : elle ne lit ni créance ni paiement, et l'isolation stricte
    // du module (I-4) commencerait à se défaire par le partage d'un scope.
    GoRoute(
      path: AppRoutesNames.boutiqueAchats,
      // Précédent du navigateur : le panier en cours pose la question.
      onExit: RouteExitGuard.onExit,
      builder: (context, state) => const BoutiquePage(),
    ),
    GoRoute(
      path: AppRoutesNames.boutiqueDashboard,
      builder: (context, state) => const BoutiqueDashboardPage(),
    ),
    // L'historique a laissé place au tableau de bord : un favori sur l'ancienne
    // adresse y mène au lieu d'une page introuvable.
    GoRoute(
      path: AppRoutesNames.boutiqueLegacyHistory,
      redirect: (context, state) => AppRoutesNames.boutiqueDashboard,
    ),
    // Les dépenses ont leur menu et leur scope : il hydrate le registre et le
    // taux du jour au montage. Aucun partage avec Finances — la source de fonds
    // ne débite aucune caisse en V1.
    ShellRoute(
      builder: (context, state, child) => ExpenseFeatureScope(child: child),
      routes: [
        GoRoute(
          path: AppRoutesNames.expenseDashboard,
          builder: (context, state) => const ExpenseDashboardPage(),
        ),
        GoRoute(
          path: AppRoutesNames.expenseRegister,
          builder: (context, state) => const ExpenseRegisterPage(),
        ),
        GoRoute(
          path: AppRoutesNames.expenseQueue,
          builder: (context, state) => const ExpenseQueuePage(),
        ),
      ],
    ),
    // Communication : en ligne seulement, aucun scope à hydrater.
    GoRoute(
      path: AppRoutesNames.communicationAnnouncements,
      // Précédent du navigateur : un communiqué en rédaction pose la question.
      onExit: RouteExitGuard.onExit,
      builder: (context, state) => const AnnouncementsPage(),
    ),
    GoRoute(
      path: AppRoutesNames.communicationTemplates,
      builder: (context, state) => const AnnouncementTemplatesPage(),
    ),
    // Ressources humaines : le fichier du personnel, le Pointage et la Paie,
    // chacun son cubit, monté par sa page.
    GoRoute(
      path: AppRoutesNames.hrStaffFile,
      // La fiche d'un agent et le formulaire de contrat sont poussés par-dessus
      // (`Navigator`) : Précédent du navigateur quitte cette route, et consulte
      // donc leur garde.
      onExit: RouteExitGuard.onExit,
      builder: (context, state) => const StaffFilePage(),
    ),
    GoRoute(
      path: AppRoutesNames.hrStaffAttendance,
      builder: (context, state) => const StaffAttendancePage(),
    ),
    GoRoute(
      path: AppRoutesNames.hrPayroll,
      builder: (context, state) => const PayrollPage(),
    ),
    // RH · Personnel : un module à part sur le même fichier local. La page
    // agent est poussée par-dessus les deux écrans, d'où la garde de sortie.
    GoRoute(
      path: AppRoutesNames.hrPersonnelDashboard,
      onExit: RouteExitGuard.onExit,
      builder: (context, state) => const HrDashboardPage(),
    ),
    GoRoute(
      path: AppRoutesNames.hrPersonnelFile,
      onExit: RouteExitGuard.onExit,
      builder: (context, state) => const HrPersonnelFilePage(),
    ),
    GoRoute(
      path: AppRoutesNames.hrPresenceDashboard,
      builder: (context, state) => const HrPresenceDashboardPage(),
    ),
    GoRoute(
      path: AppRoutesNames.hrPresenceRegister,
      builder: (context, state) => const HrPresenceRegisterPage(),
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
          builder: (context, state) => const ClassPresencePage(),
        ),
        GoRoute(
          path: AppRoutesNames.justifications,
          builder: (context, state) => const JustificationQueuePage(),
        ),
        StudentRecordRoutes.disciplinaryDetail(),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => DocumentsFeatureScope(child: child),
      routes: [
        GoRoute(
          path: AppRoutesNames.documentsStudents,
          builder: (context, state) => const DocumentsPage(),
          routes: [StudentRecordRoutes.documentsCatalog()],
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

  static const _shellPageKey = ValueKey<String>('home-shell');

  static Page<void> _shellPage(String? subMenuId) => MaterialPage<void>(
    key: _shellPageKey,
    child: HomePage(subMenuId: subMenuId),
  );
}
