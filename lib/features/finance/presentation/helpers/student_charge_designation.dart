import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/fee_tariff_code.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Comment une créance se **nomme** à l'écran — un seul endroit, six écrans.
///
/// La nature seule (« Frais d'examen ») rend trois lignes identiques dès qu'un
/// niveau porte plusieurs tranches d'un même frais : trois montants, trois
/// échéances, aucun moyen de savoir laquelle on coche ni laquelle on valide. Le
/// libellé du référentiel porte le rang (« Organisation matériel examens —
/// 2/3 »), et le code du tarif le confirme d'un coup d'œil (« OM2 »).
///
/// La règle vit ici et pas dans les widgets parce qu'elle avait déjà divergé :
/// le guichet lisait le libellé, l'étape « Frais » du wizard lisait la nature et
/// ne retombait sur le libellé que si la nature lui était inconnue — deux
/// cascades inverses sur la même donnée.

/// Ce que le guichet doit LIRE pour désigner un frais.
///
/// | libellé | code utile | rendu |
/// |---|---|---|
/// | oui | oui | `Organisation matériel — 2/3 (OM2)` |
/// | oui | non | `Organisation matériel — 2/3` |
/// | non | oui | `Frais d'examen (OM2)` |
/// | non | non | `Frais d'examen` |
///
/// « Code utile » est tranché par [meaningfulTariffCode] : un code qui vaut la
/// nature ne distingue rien et ne s'affiche pas.
///
/// Le repli sur la nature localisée sert la créance *ad hoc*, qui peut n'avoir
/// aucun libellé — un frais sans nom du tout serait pire que trop générique.
/// Le libellé, lui, ne se traduit pas : il vient du serveur.
String chargeDesignation(StudentCharge charge, AppLocalizations l10n) =>
    feeDesignation(
      label: charge.label,
      feeCode: charge.feeCode,
      feeTariffCode: charge.feeTariffCode,
      l10n: l10n,
    );

/// La même règle, sur les trois valeurs brutes.
///
/// Une **imputation** ne porte pas de `StudentCharge` : elle a le libellé GELÉ à
/// l'encaissement — ce que le guichet a validé ce jour-là, et qui ne se
/// recalcule pas — sa nature, et le code joint depuis la grille. Elle entre donc
/// par ici, sans qu'on ait à lui fabriquer une créance qu'elle n'est pas.
String feeDesignation({
  required String label,
  required String feeCode,
  required String? feeTariffCode,
  required AppLocalizations l10n,
}) {
  final trimmed = label.trim();
  final base = trimmed.isEmpty ? feeCode.localizedFeeLabel(l10n) : trimmed;
  final code = meaningfulTariffCode(code: feeTariffCode, feeCode: feeCode);

  return code == null ? base : l10n.chargeDesignationWithTariffCode(base, code);
}
