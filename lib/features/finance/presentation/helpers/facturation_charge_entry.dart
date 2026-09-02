import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';

/// Une ligne de la page d'encaissement : un frais payable, la façon dont il est
/// réglé, et les montants des deux côtés.
///
/// Vit hors de la page parce que la page tient la liste et que la section
/// « Frais à régler » la rend : c'est tout ce que les deux partagent.
///
/// **Deux montants, une seule vérité à la fois.** Quand la devise de règlement
/// diffère de celle de la créance, la ligne porte deux champs — l'imputé et le
/// reçu — et [tenderIsSource] dit lequel le caissier vient de taper. C'est ce
/// drapeau qui empêche de réécrire un champ sous ses doigts : on ne recalcule
/// jamais celui qui a le curseur.
class FacturationChargeEntry {
  final StudentCharge charge;

  /// Le montant **imputé**, dans la devise de la créance.
  final TextEditingController controller;

  /// Le montant **posé sur le comptoir**, dans la devise de règlement. Vide et
  /// inutilisé tant que les deux devises sont la même.
  final TextEditingController tenderController;

  bool selected;

  /// La devise dans laquelle CE frais est réglé. `null` = celle de la créance,
  /// c'est-à-dire le cas courant, qui ne coûte rien.
  String? tenderCurrency;

  /// Le dernier champ édité est celui du comptoir.
  bool tenderIsSource = false;

  FacturationChargeEntry(this.charge)
    : controller = TextEditingController(),
      tenderController = TextEditingController(),
      selected = false;

  int get remainingInCents => chargeRemainingInCents(charge);

  /// La devise de règlement effective — celle de la créance par défaut.
  String get effectiveTenderCurrency => tenderCurrency ?? charge.currency;

  /// Vrai quand cette ligne convertit : c'est le seul cas où elle montre deux
  /// champs.
  bool get isConverted =>
      selected && effectiveTenderCurrency != charge.currency;

  int get effectiveCents => effectiveAllocationCents(
    selected: selected,
    rawAmount: controller.text,
    remainingInCents: remainingInCents,
  );

  /// Ce qui est **tendu**, tel que saisi — jamais borné au restant : le parent
  /// pose ce qu'il pose, et l'excédent devient de la monnaie à rendre.
  int get tenderedCents {
    final parsed = parseMonetaryAmount(tenderController.text);
    if (parsed == null || parsed <= 0) return 0;
    return (parsed * 100).round();
  }

  /// Écrit la valeur **dérivée** dans l'autre champ.
  ///
  /// Aucun verrou n'est nécessaire pour éviter la boucle : `onChanged` d'un
  /// `TextField` ne part que sur une frappe, jamais sur une écriture
  /// programmatique du contrôleur. Écrire ici ne relance donc pas le calcul
  /// inverse.
  ///
  /// L'égalité en tête sert à autre chose : réassigner `text` replace le curseur
  /// en fin de champ. Ne rien écrire quand la valeur ne change pas évite ce
  /// saut sur un champ que le caissier vient peut-être de reprendre.
  void writeDerived(TextEditingController target, String text) {
    if (target.text == text) return;
    target.text = text;
  }

  void dispose() {
    controller.dispose();
    tenderController.dispose();
  }
}
