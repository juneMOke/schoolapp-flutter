import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/outbox_push_access.dart';

/// Les droits de poussée, figés en VALEURS DU FIL et recopiés du back
/// (`@RequiresPermission` / `@RequiresBothPermissions` des contrôleurs `/sync`,
/// plus les contrôles de droit faits dans le code), relevés le 2026-11-18 sur
/// `origin/main`.
///
/// Comparer une constante à elle-même ne prouverait rien : ce test dit ce que
/// le serveur exige, et rougit si une constante dérive. Une valeur plus stricte
/// que le serveur retiendrait pour toujours une écriture qu'il aurait acceptée.
void main() {
  ({Set<String> wires, bool all}) of(ModuleAccess a) =>
      (wires: a.requires.map((p) => p.wire).toSet(), all: a.requiresAll);

  void pin(String route, ModuleAccess access, Set<String> wires) {
    final actual = of(access);
    expect(actual.wires, wires, reason: route);
    // Une seule permission : la conjonction n'a pas de sens. Plusieurs : le
    // serveur les exige toutes.
    if (wires.length > 1) expect(actual.all, isTrue, reason: route);
  }

  test('présence et discipline', () {
    pin('POST /sync/attendance', kAttendanceRecordAccess, {'attendance.write'});
    pin('POST /sync/attendance-closures', kAttendanceAmendPushAccess, {
      'attendance.amend',
    });
    pin('POST /sync/disciplinary-cases', kDisciplineInstructAccess, {
      'discipline.write',
    });
  });

  test('argent', () {
    pin('POST /sync/payments', kPaymentCollectAccess, {
      'finance.payment.write',
      'editique.write',
    });
    pin('POST /sync/payment-corrections', kPaymentCorrectionPushAccess, {
      'finance.payment.cancel',
      'editique.cancel',
    });
    pin(
      'POST /sync/payment-corrections (remplaçant)',
      kPaymentReplacementPushAccess,
      {
        'finance.payment.cancel',
        'editique.cancel',
        'finance.payment.write',
        'editique.write',
      },
    );
    pin('POST /finance/payments/{id}/receipt', kTicketReceiptRetryAccess, {
      'editique.write',
    });
    pin('POST /sync/boutique/sales', kBoutiqueCollectAccess, {
      'boutique.sale.write',
      'editique.write',
    });
    pin('POST /sync/expenses', kExpenseWriteAccess, {'expense.write'});
    pin('POST /sync/expenses (avance)', kStaffAdvancePushAccess, {
      'expense.write',
      'hr.pay.read',
    });
    pin('…/decision', kExpenseDecideAccess, {'expense.decide'});
    pin('…/payment', kExpensePayAccess, {'expense.pay'});
    pin('…/reopen', kExpenseReopenAccess, {'expense.reopen'});
    pin('…/deletion', kExpenseWithdrawAccess, {'expense.delete'});
  });

  test('RH et paie', () {
    pin('POST /sync/staff-members', kStaffWriteAccess, {'hr.staff.write'});
    pin('contrats, corrections, profils, paie', kPayrollWriteAccess, {
      'hr.pay.write',
    });
    pin('réglages, catalogue des retenues', kPayrollManageAccess, {
      'hr.pay.manage',
    });
    pin('gestes de direction de la paie', kPayrollDirectionGesturePushAccess, {
      'hr.pay.write',
      'hr.pay.manage',
    });
    pin('…/documents', kStaffDocumentPushAccess, {'hr.document.write'});
    pin('POST /sync/staff-attendance', kStaffAttendanceWriteAccess, {
      'hr.attendance.write',
    });
    pin('PUT /sync/staff-attendance-settings', kStaffAttendanceManageAccess, {
      'hr.attendance.manage',
    });
    pin('verrou CLOSE_MONTH', kStaffMonthClosePushAccess, {
      'hr.attendance.write',
      'hr.attendance.manage',
    });
    pin('verrou REOPEN_MONTH', kStaffMonthReopenPushAccess, {
      'hr.attendance.write',
      'hr.attendance.reopen',
    });
  });

  test('scolarité', () {
    pin('POST /sync/enrollments', kEnrollmentSubmitAccess, {
      'enrollment.write',
      'editique.write',
    });
    pin(
      'POST /sync/enrollment-level-corrections',
      kEnrollmentLevelCorrectAccess,
      {'enrollment.level.correct'},
    );
    pin('POST /sync/enrollment-suspensions', kEnrollmentSuspendAccess, {
      'enrollment.suspend',
    });
    pin('…/students/{id}/photo', kStudentPhotoWriteAccess, {
      'student.photo.write',
    });
    pin('POST /sync/classroom-transfers', kClassroomWritePushAccess, {
      'classroom.write',
    });
    pin('évaluations, notes, sujet, copie', kGradeWritePushAccess, {
      'academics.grade.write',
    });
    pin('POST /sync/academics/cotes', kGradeEnterPushAccess, {
      'academics.grade.enter',
    });
    pin('programme et journal', kProgrammeWritePushAccess, {
      'academics.programme.write',
    });
  });
}
