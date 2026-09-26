import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_correction_context.dart';

/// L'écart entre le remplaçant et l'origine, rendu neutre (« +20,00 $ »,
/// « −100,00 $ »), `null` quand il est nul dans toutes les devises.
///
/// Neutre (D8) : pour un « Mauvais montant », l'écart est presque toujours une
/// faute de frappe, et aucun argent n'est à rendre.
String? correctionGapLabel(MoneyBag replacement, MoneyBag origin) {
  final currencies = {...replacement.currencies, ...origin.currencies};
  final parts = <String>[];
  for (final currency in currencies.toList()..sort()) {
    final diff =
        (replacement.amountIn(currency)?.amountInCents ?? 0) -
        (origin.amountIn(currency)?.amountInCents ?? 0);
    if (diff == 0) continue;
    final sign = diff > 0 ? '+' : '−';
    parts.add('$sign${MoneyFormat.format(Money.parse(diff.abs(), currency))}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Le remplaçant ne change rien à l'origine : mêmes tranches, mêmes montants,
/// même jour. « Annuler » est alors le bon geste.
bool correctionUnchanged({
  required FacturationPaymentCorrectionContext correction,
  required Map<String, int> replacementCentsByCharge,
  required DateTime replacementDay,
}) {
  final origin = correction.origin.centsByCharge;
  if (origin.length != replacementCentsByCharge.length) return false;
  for (final entry in origin.entries) {
    if (replacementCentsByCharge[entry.key] != entry.value) return false;
  }
  return SchoolTime.today(correction.originPaidAt) == replacementDay;
}

/// Le remplaçant garde l'INSTANT d'origine tant que le jour n'a pas changé
/// (D2) : l'argent est entré ce jour-là, à cette heure-là, et la caisse du jour
/// d'origine ne bouge que de l'écart.
RecordPaymentDraft withOriginInstant(
  RecordPaymentDraft draft,
  FacturationPaymentCorrectionContext correction,
  DateTime replacementDay,
) {
  if (SchoolTime.today(correction.originPaidAt) != replacementDay) return draft;
  return RecordPaymentDraft(
    studentId: draft.studentId,
    academicYearId: draft.academicYearId,
    method: draft.method,
    paidAt: correction.origin.paidAt,
    payerFirstName: draft.payerFirstName,
    payerLastName: draft.payerLastName,
    payerMiddleName: draft.payerMiddleName,
    payerPhoneNumber: draft.payerPhoneNumber,
    amounts: draft.amounts,
    tenders: draft.tenders,
    allocations: draft.allocations,
  );
}
