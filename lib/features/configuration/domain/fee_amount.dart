import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';

/// Conversion d'un montant saisi en centimes, et retour.
///
/// **Le passage par les centimes est le seul endroit où l'argent peut se
/// perdre** dans ce module. Un `(montant * 100).toInt()` naïf transforme
/// `80,07` en 8006 : la représentation binaire de 80,07 vaut 80,069999…, et la
/// troncature emporte le centime. Arrondir, et non tronquer, est ce qui ferme
/// ce trou.
class FeeAmount {
  const FeeAmount._();

  /// Montant saisi (français, virgule décimale) → centimes.
  ///
  /// `null` si la saisie n'est pas un nombre, ou si elle est négative : un
  /// tarif négatif n'a pas de sens et le serveur le refuserait.
  static int? centsFromInput(String raw) {
    final amount = parseMonetaryAmount(raw);
    if (amount == null || amount.isNaN || amount.isInfinite) return null;
    if (amount < 0) return null;
    return (amount * 100).round();
  }

  /// Centimes → montant affichable.
  static double unitsFromCents(int cents) => cents / 100;

  /// Centimes → chaîne saisissable, en français.
  static String inputFromCents(int cents) =>
      formatMonetaryAmount(unitsFromCents(cents)).replaceAll(' ', '');

  /// Centimes → montant formaté avec sa devise, « FC » pour le franc congolais.
  ///
  /// Le code ISO circule sur le fil ; c'est l'abréviation d'usage qui s'affiche.
  /// Ce module était le seul à le savoir — [MoneyFormat] le sait maintenant pour
  /// toute l'application, et cette méthode n'est plus qu'une façade.
  static String display(int cents, String currency) =>
      MoneyFormat.format(Money.parse(cents, currency));

  /// Totaux **par devise**.
  ///
  /// Jamais additionnées entre elles : 100 USD et 100 CDF ne font pas 200 de
  /// quoi que ce soit, et un total unique donnerait un chiffre que personne ne
  /// peut vérifier.
  ///
  /// Ce module avait écrit ce groupement avant que le socle n'existe. Il délègue
  /// désormais à [MoneyBag] — même résultat, plus les devises normalisées et
  /// l'ordre stable, et un exemplaire de moins de la seule logique qu'il ne faut
  /// surtout pas voir diverger.
  static Map<String, int> totalsByCurrency(
    Iterable<({String currency, int amountInCents})> fees,
  ) => {
    for (final entry in MoneyBag.sumBy(
      fees,
      (fee) => Money.parse(fee.amountInCents, fee.currency),
    ).entries)
      entry.currency: entry.amountInCents,
  };
}
