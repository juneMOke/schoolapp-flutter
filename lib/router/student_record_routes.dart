import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/leave_replayed_route.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/disciplinary_student_detail_page.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_catalog_page.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/features/student/presentation/widgets/student_identity_gate.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/route_parameters.dart';

/// Les fiches d'un élève qui ont une adresse : Facturation (et son
/// encaissement), catalogue des documents, dossier disciplinaire.
///
/// La navigation leur passe l'identité de l'élève par `extra`. Une adresse
/// rechargée, collée ou ouverte au Ctrl+clic n'en a pas : la fiche relit
/// alors l'identité en base locale ([StudentIdentityGate]) au lieu d'afficher
/// « contexte indisponible ».
abstract final class StudentRecordRoutes {
  static const _ids = ['studentId', 'academicYearId'];

  static String _studentId(GoRouterState state) =>
      state.pathParameters['studentId'] ?? '';

  static String _yearId(GoRouterState state) =>
      state.pathParameters['academicYearId'] ?? '';

  /// `detail/:studentId/:academicYearId`, sous la liste Facturation.
  static GoRoute facturationDetail() => GoRoute(
    path: 'detail/:studentId/:academicYearId',
    redirect: (context, state) => hasRequiredPathParameters(state, _ids)
        ? null
        : AppRoutesNames.facturations,
    builder: (context, state) {
      final intent = FacturationDetailIntent.fromRouteContext(
        studentId: _studentId(state),
        academicYearId: _yearId(state),
        extra: state.extra,
      );
      if (intent.hasStudentIdentity) {
        return FacturationDetailPage(intent: intent);
      }
      return StudentIdentityGate(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        builder: (identity) => FacturationDetailPage(
          intent: identity == null ? intent : intent.withIdentity(identity),
        ),
      );
    },
    routes: [_createPayment()],
  );

  /// Encaissement : écran plein empilé SUR la fiche (`push`), qui rend `true`
  /// au succès pour que la fiche resynchronise ses listes. La garde de
  /// paramètres de la fiche s'applique aussi ici — les redirects de la pile
  /// matchée sont tous joués.
  ///
  /// Il ne se rouvre pas seul : il travaille sur les créances que la fiche
  /// lui confie. Sans elles (adresse rechargée), retour à la fiche, d'où
  /// l'encaissement repart sur des soldes relus — jamais sur un formulaire
  /// vide qui ferait croire à un élève sans dette.
  static GoRoute _createPayment() => GoRoute(
    path: 'encaissement',
    // Précédent du navigateur pendant un encaissement : retenu
    // (cf. `RouteExitGuard`).
    onExit: RouteExitGuard.onExit,
    redirect: (context, state) => createPaymentRedirect(
      extra: state.extra,
      studentId: _studentId(state),
      academicYearId: _yearId(state),
    ),
    builder: (context, state) {
      final intent = FacturationCreatePaymentIntent.fromRouteContext(
        studentId: _studentId(state),
        academicYearId: _yearId(state),
        extra: state.extra,
      );
      // Rejoué par l'historique : déjà écrit, ou sans ses créances (F5).
      if (intent.isSpent || !intent.hasDisplayContext) {
        return LeaveReplayedRoute(
          fallbackLocation: AppRoutesNames.facturationDetailPath(
            studentId: intent.studentId,
            academicYearId: intent.academicYearId,
          ),
        );
      }
      return FacturationCreatePaymentPage(intent: intent);
    },
  );

  /// `null` quand l'encaissement a ses créances ; sinon l'adresse de la fiche,
  /// où il repart.
  @visibleForTesting
  static String? createPaymentRedirect({
    required Object? extra,
    required String studentId,
    required String academicYearId,
  }) => extra is FacturationCreatePaymentIntent
      ? null
      : AppRoutesNames.facturationDetailPath(
          studentId: studentId,
          academicYearId: academicYearId,
        );

  /// `catalogue/:studentId/:academicYearId`, sous la liste Documents.
  static GoRoute documentsCatalog() => GoRoute(
    path: 'catalogue/:studentId/:academicYearId',
    redirect: (context, state) => hasRequiredPathParameters(state, _ids)
        ? null
        : AppRoutesNames.documentsStudents,
    builder: (context, state) {
      final intent = DocumentsCatalogIntent.fromRouteContext(
        studentId: _studentId(state),
        academicYearId: _yearId(state),
        extra: state.extra,
      );
      if (intent.hasDisplayContext) {
        return DocumentsCatalogPage(intent: intent);
      }
      return StudentIdentityGate(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        builder: (identity) => DocumentsCatalogPage(
          intent: identity == null ? intent : intent.withIdentity(identity),
        ),
      );
    },
  );

  /// Le dossier disciplinaire d'un élève.
  static GoRoute disciplinaryDetail() => GoRoute(
    path: AppRoutesNames.disciplinaryStudentDetail,
    redirect: (context, state) => hasRequiredPathParameters(state, _ids)
        ? null
        : AppRoutesNames.presences,
    builder: (context, state) {
      final intent = DisciplinaryStudentDetailIntent.fromRouteContext(
        studentId: _studentId(state),
        academicYearId: _yearId(state),
        extra: state.extra,
      );
      if (intent.hasDisplayContext) {
        return DisciplinaryStudentDetailPage(intent: intent);
      }
      return StudentIdentityGate(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        builder: (identity) => DisciplinaryStudentDetailPage(
          intent: identity == null ? intent : intent.withIdentity(identity),
        ),
      );
    },
  );
}
