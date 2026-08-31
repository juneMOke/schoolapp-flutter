import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Les trois sommes d'un jeu de créances — **par devise**.
///
/// Ces trois totaux étaient recalculés à la main sur cinq écrans, chacun par un
/// `.fold()` qui additionnait toutes devises confondues puis étiquetait le
/// résultat avec `charges.first.currency`. Un élève devant 425,00 $ et
/// 90 000 FC s'y voyait annoncer « 9 042 500 USD ».
///
/// Le regroupement vit ici, une seule fois, et rend un [MoneyBag] — qui n'a
/// délibérément pas de total.
extension StudentChargeMoney on Iterable<StudentCharge> {
  /// Ce qui a été facturé.
  MoneyBag get expectedBag => MoneyBag.sumBy(
    this,
    (charge) => charge._money(charge.expectedAmountInCents),
  );

  /// Ce qui a été payé, **composé** : miroir serveur + encaissements de ce
  /// poste pas encore remontés (FRONT §5).
  MoneyBag get paidTotalBag =>
      MoneyBag.sumBy(this, (charge) => charge._money(charge.paidTotalInCents));

  /// Ce qui reste dû, composé et déjà borné à zéro par l'entité.
  MoneyBag get remainingBag =>
      MoneyBag.sumBy(this, (charge) => charge._money(charge.remainingInCents));
}

extension on StudentCharge {
  /// Les montants de l'entité sont des `double` — un héritage du contrat online,
  /// que le socle ramène en centimes entiers dès la lecture. L'arrondi, et non
  /// la troncature : `80,07` vaut `80.069999…` en binaire, et tronquer y
  /// emporterait le centime.
  Money _money(double cents) => Money.parse(cents.round(), currency);
}
