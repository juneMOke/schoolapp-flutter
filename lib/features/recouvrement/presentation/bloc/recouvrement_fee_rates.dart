import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_rate.dart';

/// Le recouvrement d'**un poste, dans une devise**.
class RecouvrementFeeRate extends Equatable {
  final String feeCode;
  final String currency;
  final int expectedInCents;

  /// Perçu composé. Peut **dépasser** l'attendu — c'est un arriéré qui se solde
  /// — sans que le taux franchisse 100.
  final int paidInCents;

  /// Reste planché créance par créance. C'est lui qui rend la ligne lisible
  /// quand le perçu dépasse l'attendu : sans lui, l'écran montrerait un perçu
  /// supérieur à l'attendu à côté d'une barre aux deux tiers, et rien
  /// n'expliquerait l'écart.
  final int remainingInCents;

  const RecouvrementFeeRate({
    required this.feeCode,
    required this.currency,
    required this.expectedInCents,
    required this.paidInCents,
    required this.remainingInCents,
  });

  int get rate => RecoveryRate.of(
    expectedInCents: expectedInCents,
    remainingInCents: remainingInCents,
  );

  bool get hasNoExpectation => RecoveryRate.hasNoExpectation(expectedInCents);

  @override
  List<Object?> get props => [
    feeCode,
    currency,
    expectedInCents,
    paidInCents,
    remainingInCents,
  ];
}

/// Tous les postes facturés dans **une même devise**, et le total du groupe.
///
/// Un groupe par devise, jamais un classement unique : comparer un taux en
/// francs à un taux en dollars est légitime — ce sont des pourcentages — mais
/// additionner leurs montants ne l'est pas.
class RecouvrementCurrencyGroup extends Equatable {
  final String currency;

  /// Les postes, **triés par attendu décroissant** : ceux qui pèsent d'abord, et
  /// un ordre qui ne se remanie pas d'un rafraîchissement à l'autre. Le code de
  /// nature départage à égalité, pour que le tri soit total.
  final List<RecouvrementFeeRate> fees;

  final int expectedInCents;
  final int paidInCents;
  final int remainingInCents;

  const RecouvrementCurrencyGroup({
    required this.currency,
    required this.fees,
    required this.expectedInCents,
    required this.paidInCents,
    required this.remainingInCents,
  });

  int get rate => RecoveryRate.of(
    expectedInCents: expectedInCents,
    remainingInCents: remainingInCents,
  );

  bool get hasNoExpectation => RecoveryRate.hasNoExpectation(expectedInCents);

  /// L'attendu du poste le plus lourd du groupe — le dénominateur de la
  /// **longueur** des barres. `0` si le groupe n'attend rien nulle part, auquel
  /// cas les barres restent à zéro plutôt que de diviser par lui.
  int get heaviestExpectedInCents =>
      fees.isEmpty ? 0 : fees.first.expectedInCents;

  @override
  List<Object?> get props => [
    currency,
    fees,
    expectedInCents,
    paidInCents,
    remainingInCents,
  ];
}

/// Ventile le registre en groupes de devise, puis en postes.
///
/// **Pur** : on lui donne ce que le grand-livre a rendu, il rend ce que l'écran
/// affiche.
class RecouvrementFeeRatesProjector {
  const RecouvrementFeeRatesProjector._();

  /// Les groupes, triés par code de devise croissant — le même ordre partout,
  /// pour que deux écrans ne présentent jamais les mêmes devises autrement.
  ///
  /// Un groupe **sans poste** n'est pas produit : on n'affiche pas de section
  /// vide. Un poste sans attendu, lui, est conservé — il porte peut-être un
  /// versement, et le taire ferait disparaître de l'argent perçu.
  static List<RecouvrementCurrencyGroup> project(
    List<LocalRecoveryLine> lines,
  ) {
    if (lines.isEmpty) return const <RecouvrementCurrencyGroup>[];

    // (devise → code de frais → totaux)
    final byCurrency = <String, Map<String, List<int>>>{};

    for (final line in lines) {
      for (final charge in line.charges) {
        final fees = byCurrency[charge.currency] ??= <String, List<int>>{};
        final totals = fees[charge.feeCode] ??= <int>[0, 0, 0];
        totals[0] += charge.expectedInCents;
        totals[1] += charge.paidTotalInCents;
        totals[2] += charge.remainingInCents;
      }
    }

    final currencies = byCurrency.keys.toList()..sort();
    return [
      for (final currency in currencies)
        _group(currency, byCurrency[currency]!),
    ];
  }

  static RecouvrementCurrencyGroup _group(
    String currency,
    Map<String, List<int>> byFee,
  ) {
    final fees =
        [
          for (final entry in byFee.entries)
            RecouvrementFeeRate(
              feeCode: entry.key,
              currency: currency,
              expectedInCents: entry.value[0],
              paidInCents: entry.value[1],
              remainingInCents: entry.value[2],
            ),
        ]..sort((a, b) {
          final byWeight = b.expectedInCents.compareTo(a.expectedInCents);
          return byWeight != 0 ? byWeight : a.feeCode.compareTo(b.feeCode);
        });

    var expected = 0;
    var paid = 0;
    var remaining = 0;
    for (final fee in fees) {
      expected += fee.expectedInCents;
      paid += fee.paidInCents;
      remaining += fee.remainingInCents;
    }

    return RecouvrementCurrencyGroup(
      currency: currency,
      fees: fees,
      expectedInCents: expected,
      paidInCents: paid,
      remainingInCents: remaining,
    );
  }
}
