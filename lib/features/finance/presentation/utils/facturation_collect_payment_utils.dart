import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Helpers purs de la modale d'encaissement (spec MODALE-12).
///
/// Le montant effectif d'une allocation est toujours borné au restant dû du
/// frais : `min(max(0, saisie), attendu − payé)`. Une allocation à 0 n'est pas
/// retenue ; la somme des montants effectifs alimente le total du paiement.

/// Restant dû d'un frais, en cents (jamais négatif).
int chargeRemainingInCents(StudentCharge charge) {
  final remaining = charge.expectedAmountInCents - charge.amountPaidInCents;
  return remaining <= 0 ? 0 : remaining.round();
}

/// Saisie monétaire convertie en cents (0 si vide, invalide ou ≤ 0).
int parseAmountToCents(String rawAmount) {
  final parsed = parseMonetaryAmount(rawAmount);
  if (parsed == null || parsed <= 0) {
    return 0;
  }
  return (parsed * 100).round();
}

/// Montant effectif d'une allocation, borné au restant dû.
///
/// Retourne 0 si la ligne n'est pas cochée.
int effectiveAllocationCents({
  required bool selected,
  required String rawAmount,
  required int remainingInCents,
}) {
  if (!selected) {
    return 0;
  }
  final parsed = parseAmountToCents(rawAmount);
  if (parsed <= 0) {
    return 0;
  }
  return parsed > remainingInCents ? remainingInCents : parsed;
}

/// `true` si la saisie dépasse le restant dû (déclenche l'avertissement ambre).
bool isAmountOverflowing({
  required bool selected,
  required String rawAmount,
  required int remainingInCents,
}) {
  if (!selected) {
    return false;
  }
  return parseAmountToCents(rawAmount) > remainingInCents;
}
