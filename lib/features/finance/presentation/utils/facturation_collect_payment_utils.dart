import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Helpers purs de la modale d'encaissement (spec MODALE-12).
///
/// Le montant effectif d'une allocation est toujours borné au restant dû du
/// frais : `min(max(0, saisie), attendu − payé)`. Une allocation à 0 n'est pas
/// retenue ; la somme des montants effectifs alimente le total du paiement.

/// Restant dû COMPOSÉ d'un frais, en cents (jamais négatif) : miroir serveur
/// MOINS les encaissements de ce poste non encore remontés (FRONT §5/§6). C'est
/// cette borne — pas le miroir serveur seul — qui empêche de re-percevoir sur le
/// même guichet un poste déjà soldé localement (prévention locale du trop-perçu,
/// §8 #3-4).
int chargeRemainingInCents(StudentCharge charge) =>
    charge.remainingInCents.round();

/// Ligne de grille désignée par un frais, ou `null` s'il n'en désigne aucune.
///
/// L'entité online porte `feeTariffId` en `String` **non nullable** : le pont
/// depuis le grand-livre local replie l'absence de tarif sur `''`, parce que
/// c'est la forme qu'attendent les écrans de lecture. Le guichet, lui, ne peut
/// pas envoyer cette chaîne — ce n'est ni un uuid, ni un `null`, et le serveur
/// ne saurait pas la lire comme « créance hors grille ».
///
/// C'est donc ici, au point de sortie, que l'absence redevient `null` — pas dans
/// le mapper, dont la forme sert le reste de Facturation.
String? designatedFeeTariffId(StudentCharge charge) {
  final tariffId = charge.feeTariffId.trim();
  return tariffId.isEmpty ? null : tariffId;
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
