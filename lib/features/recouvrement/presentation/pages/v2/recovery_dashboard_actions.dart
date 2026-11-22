import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_viewer.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/student/recovery_student_sheet.dart';

/// Les gestes du tableau de bord qui **sortent** de la page : ouvrir un
/// export (O3), la fiche d'un élève (O4), ou le contrôle des frais (R15).

/// Ouvre la visionneuse d'export (O3) sur la liste entière de [query]
/// — la recherche ne restreint pas l'export (Q5). La bascule PDF | Excel
/// change de document sans fermer ; chaque fichier n'est demandé qu'une fois
/// (un PDF consomme un numéro de pièce).
Future<void> openRecoveryExport(
  BuildContext context, {
  required RecoveryStudentsQuery query,
  required RecoveryExportFormat format,
  required String title,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showEteeloAdaptiveDialog<void>(
    context: context,
    builder: (_) => RecoveryExportViewer(
      query: query,
      title: title,
      initialFormat: format,
      repository: getIt<RecoveryDashboardRepository>(),
      countPending: getIt<CountPendingPaymentsUseCase>(),
    ),
  );
}

/// Ouvre la fiche d'un élève (O4) : tous ses frais, chacun dans sa devise,
/// lus sur l'appareil. « Notifier le parent » et « Marquer à renvoyer » mènent
/// au contrôle des frais (R16).
Future<void> openRecoveryStudentSheet(
  BuildContext context, {
  required String academicYearId,
  required String studentId,
  required String displayName,
  String? classroomId,
  required List<String> feeCodes,
}) => showRecoveryStudentSheet(
  context,
  academicYearId: academicYearId,
  studentId: studentId,
  displayName: displayName,
  onOpenControl: () => openControlFromDashboard(
    context,
    feeCodes: feeCodes,
    classroomId: classroomId ?? feeControlUnassigned,
  ),
);

/// Ouvre **Contrôle des frais** dans la coquille (R15) sur ces frais, cette
/// classe (si connue) et cette situation. Le sous-menu actif devient
/// « Contrôle des frais ».
void openControlFromDashboard(
  BuildContext context, {
  required List<String> feeCodes,
  String? classroomId,
  StudentChargeStatus? situation,
}) => openFeeControl(
  context,
  FeeControlIntent(
    feeCodes: feeCodes,
    classroomId: classroomId,
    situation: switch (situation) {
      null => FeeControlPaymentFilter.all,
      StudentChargeStatus.due => FeeControlPaymentFilter.none,
      StudentChargeStatus.partial => FeeControlPaymentFilter.partial,
      StudentChargeStatus.paid => FeeControlPaymentFilter.settled,
    },
  ),
);

/// La classe que le contrôle reprend depuis un périmètre du tableau de bord :
/// la classe elle-même, sinon rien (la classe de la dernière visite, R12).
String? controlClassroomOf(RecoveryQuestion question) =>
    question.scope == RecoveryScopeKind.classroom ? question.scopeId : null;
