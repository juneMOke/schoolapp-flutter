import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';

/// Des montants de plusieurs devises, groupés — **et jamais totalisés**.
///
/// ## Pourquoi il n'y a pas de `total`
///
/// 425,00 $ et 90 000 FC ne font pas 9 042 500 de quoi que ce soit. Leur somme
/// n'existe pas — pas « est délicate à calculer » : n'existe pas. Le front la
/// calculait pourtant à dix endroits, dont le total du versement affiché au
/// guichet, imprimé sur le ticket remis au parent, et envoyé au serveur.
///
/// Cette classe n'expose donc **aucun scalaire agrégé**. Ce n'est pas un oubli
/// d'API : c'est ce qui rend le geste impossible plutôt que déconseillé. La
/// tentation reviendra à chaque écran, et une API qui la rend possible finit
/// toujours par la voir aboutir.
///
/// ## Vide n'est pas zéro
///
/// Un sac **vide** dit « aucun montant » : un élève sans charge ne doit rien, et
/// on ne sait pas dans quelle unité il ne doit rien. Une entrée **à zéro** dit
/// autre chose : « en dollars, il ne reste rien ». Les deux se distinguent, et
/// [withoutZeros] est là pour les surfaces qui veulent élaguer.
class MoneyBag extends Equatable {
  /// Une entrée par devise, triée par code croissant — l'ordre que le serveur
  /// garantit sur `byCurrency`, pour que deux écrans ne présentent jamais les
  /// mêmes devises dans un ordre différent.
  final List<Money> entries;

  const MoneyBag._(this.entries);

  /// Aucun montant.
  static const MoneyBag empty = MoneyBag._(<Money>[]);

  /// Groupe des montants par devise.
  ///
  /// Les devises sont **normalisées au passage** : `usd` et `USD` ne font
  /// qu'une entrée. C'est le filet qui évite qu'une ligne sale du grand-livre
  /// local ne se compte deux fois.
  factory MoneyBag.of(Iterable<Money> amounts) {
    final totals = <String, int>{};
    for (final amount in amounts) {
      final currency = CurrencyCode.normalize(amount.currency);
      totals[currency] = (totals[currency] ?? 0) + amount.amountInCents;
    }
    return MoneyBag._(_sorted(totals));
  }

  /// Un sac d'un seul montant.
  factory MoneyBag.from(Money amount) => MoneyBag.of([amount]);

  /// Somme **par devise** sur une collection quelconque.
  ///
  /// C'est le remplaçant des `.fold()` qui additionnaient toutes devises
  /// confondues puis étiquetaient le résultat avec la première devise venue.
  static MoneyBag sumBy<T>(
    Iterable<T> items,
    Money Function(T item) amountOf,
  ) => MoneyBag.of(items.map(amountOf));

  static List<Money> _sorted(Map<String, int> totals) {
    final currencies = totals.keys.toList()..sort();
    return List<Money>.unmodifiable([
      for (final currency in currencies) Money(totals[currency]!, currency),
    ]);
  }

  bool get isEmpty => entries.isEmpty;

  bool get isNotEmpty => entries.isNotEmpty;

  int get length => entries.length;

  /// Vrai dès que deux devises coexistent — le prédicat sur lequel un écran
  /// bascule du rendu scalaire au rendu côte à côte.
  bool get isMultiCurrency => entries.length > 1;

  /// L'unique montant du sac, `null` s'il est vide **ou** s'il en porte
  /// plusieurs.
  ///
  /// C'est ce qui garde le rendu mono-devise identique à ce qu'il était : un
  /// écran teste `soleEntry != null` et n'a rien d'autre à changer dans ce cas.
  ///
  /// Nommé ainsi et non `single` : `Iterable.single` **lève** quand il y a
  /// autre chose qu'un élément, celui-ci rend `null`. Deux sémantiques sous un
  /// même nom finiraient par se confondre à la lecture.
  Money? get soleEntry => entries.length == 1 ? entries.first : null;

  /// Les devises portées, dans l'ordre des entrées.
  Iterable<String> get currencies => entries.map((entry) => entry.currency);

  /// Le montant dans cette devise, `null` si le sac ne la porte pas.
  ///
  /// `null` et « zéro dans cette devise » sont deux réponses différentes, et
  /// l'appelant décide de ce qu'il en fait.
  Money? amountIn(String currency) {
    final wanted = CurrencyCode.normalize(currency);
    for (final entry in entries) {
      if (entry.currency == wanted) return entry;
    }
    return null;
  }

  /// Vrai si rien n'est dû nulle part — un sac vide compris.
  bool get isAllZero => entries.every((entry) => entry.isZero);

  /// Le sac sans ses entrées nulles, pour les surfaces qui n'affichent que les
  /// devises où il reste quelque chose (une pastille d'alerte, typiquement).
  MoneyBag get withoutZeros => MoneyBag._(
    List<Money>.unmodifiable(entries.where((entry) => !entry.isZero)),
  );

  /// Fusionne deux sacs, devise par devise.
  MoneyBag operator +(MoneyBag other) =>
      MoneyBag.of([...entries, ...other.entries]);

  @override
  List<Object?> get props => [entries];

  @override
  String toString() {
    final inner = entries
        .map((entry) => '${entry.amountInCents} ${entry.currency}')
        .join(' · ');
    return 'MoneyBag($inner)';
  }
}
