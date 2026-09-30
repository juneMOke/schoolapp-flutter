import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

/// La voie de régularisation automatique (N2).
///
/// Un salaire versé en espèces hors ligne pendant qu'un autre poste rouvrait
/// la paie revient refusé `PAYROLL_REOPENED_SINCE`. Quand la paie est
/// revalidée et que le net figé de l'agent **n'a pas changé** (même montant,
/// même devise), le même versement repart, rattaché à la nouvelle validation.
/// Sinon il reste à régulariser par un humain.
class PayrollDisbursementRegularizer {
  final PayrollDao _payrolls;
  final PayrollDisbursementDao _disbursements;
  final int Function() _now;

  PayrollDisbursementRegularizer({
    required PayrollDao payrolls,
    required PayrollDisbursementDao disbursements,
    int Function()? now,
  }) : _payrolls = payrolls,
       _disbursements = disbursements,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const String reopenedSinceCode = 'PAYROLL_REOPENED_SINCE';

  /// Rend le nombre de versements remis en file.
  Future<int> run(String schoolId, {required String authorId}) async {
    final refused = [
      for (final disbursement in await _disbursements.forSchool(schoolId))
        if (disbursement.needsRegularization &&
            !disbursement.isCancelled &&
            disbursement.syncErrorCode == reopenedSinceCode)
          disbursement,
    ];
    if (refused.isEmpty) return 0;
    final headers = await _payrolls.headers(schoolId);
    final lines = await _payrolls.frozenLines(schoolId);
    var requeued = 0;
    for (final disbursement in refused) {
      final header = headers[disbursement.month];
      final validation = header?.validationGestureId;
      if (header?.status != PayrollStatus.validated ||
          validation == null ||
          validation == disbursement.validationGestureId) {
        continue;
      }
      final line = lines[disbursement.month]
          ?.where((line) => line.staffMemberId == disbursement.staffMemberId)
          .firstOrNull;
      if (line == null ||
          line.netInCents != disbursement.amount.amountInCents ||
          line.currency != disbursement.amount.currency) {
        continue;
      }
      await _disbursements.reattach(
        PayrollDisbursementRequestDto(
          disbursement: PayrollDisbursementDao.toWire(
            disbursement,
          ).underValidation(validation),
          authorId: authorId,
        ),
        schoolId: schoolId,
        nowMs: _now(),
      );
      requeued++;
    }
    return requeued;
  }
}
