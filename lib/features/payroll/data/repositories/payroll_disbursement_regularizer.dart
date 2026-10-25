import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

/// La voie de régularisation automatique (N2).
///
/// Un salaire versé en espèces hors ligne pendant qu'un autre poste rouvrait
/// la paie revient refusé `PAYROLL_REOPENED_SINCE`. Quand la paie est
/// revalidée, le même versement repart, rattaché à la nouvelle validation,
/// s'il est **dans la même devise et tient dans le reste du nouveau net**
/// (T7 : les versements sont des acomptes, plus le net entier). Sinon il
/// reste à régulariser par un humain.
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

  /// Rend le nombre de versements remis en file. Chacun repart signé par son
  /// auteur d'origine ; un versement dont l'auteur est illisible reste à
  /// régulariser à la main.
  Future<int> run(String schoolId) async {
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
    // Ce qui est déjà vivant sur chaque salaire, augmenté à chaque renvoi :
    // deux refusés ne repartent pas ensemble au-delà du net.
    final paid = <String, int>{};
    for (final live in await _disbursements.forSchool(schoolId)) {
      if (!live.isLive) continue;
      final key = '${live.month}|${live.staffMemberId}|${live.amount.currency}';
      paid[key] = (paid[key] ?? 0) + live.amount.amountInCents;
    }
    refused.sort((a, b) => a.paidAt.compareTo(b.paidAt));
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
      final key =
          '${disbursement.month}|${disbursement.staffMemberId}|'
          '${disbursement.amount.currency}';
      final already = paid[key] ?? 0;
      if (line == null ||
          line.currency != disbursement.amount.currency ||
          already + disbursement.amount.amountInCents > line.netInCents) {
        continue;
      }
      final authorId = await _disbursements.authorOf(disbursement.id);
      if (authorId == null) continue;
      final sent = await _disbursements.reattach(
        PayrollDisbursementRequestDto(
          disbursement: PayrollDisbursementDao.toWire(
            disbursement,
          ).underValidation(validation),
          authorId: authorId,
        ),
        schoolId: schoolId,
        nowMs: _now(),
      );
      if (sent) {
        requeued++;
        paid[key] = already + disbursement.amount.amountInCents;
      }
    }
    return requeued;
  }
}
