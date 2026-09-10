import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_pivot.dart';

/// Qui l'on vise, si l'on renvoyait.
enum RecouvrementCriterion {
  /// Aucun versement, nulle part sur la sélection. **Le plus conservateur**, et
  /// c'est le défaut : ce sont les seuls dont le renvoi ne fait perdre aucune
  /// recette déjà encaissée.
  noPayment,

  /// Il reste quelque chose — rien payé ou partiellement payé.
  notSettled,

  /// A versé moins qu'un plancher.
  belowThreshold,
}

/// Ce que devient un groupe si l'on renvoie les élèves visés.
class RecouvrementSimulationRow extends Equatable {
  /// Niveau du groupe. `null` est légitime — cf. [LocalRecoveryLine].
  final String? schoolLevelId;

  /// Effectif **concerné** du groupe, avant renvoi.
  final int headcount;

  /// Combien le critère vise dans ce groupe.
  final int targeted;

  const RecouvrementSimulationRow({
    required this.schoolLevelId,
    required this.headcount,
    required this.targeted,
  });

  int get remainingHeadcount => headcount - targeted;

  /// Part de l'effectif **conservée**, arrondie à l'entier. `100` sur un groupe
  /// vide : ne renvoyer personne d'un groupe sans élève ne le vide pas.
  int get keptPercent =>
      headcount <= 0 ? 100 : ((remainingHeadcount * 100) / headcount).round();

  @override
  List<Object?> get props => [schoolLevelId, headcount, targeted];
}

/// Le coût chiffré d'un renvoi. **Rien n'est appliqué** : cette entité décrit,
/// elle n'écrit pas.
class RecouvrementSimulation extends Equatable {
  /// Effectif concerné avant renvoi — la somme des groupes.
  final int headcount;

  /// Élèves visés par le critère.
  final int targeted;

  /// Les groupes, **triés par part conservée croissante** puis par identifiant :
  /// les plus abîmés en haut. C'est l'inverse du classement du bloc voisin, et
  /// c'est volontaire — là-bas on cherche qui décroche, ici ce qu'on casserait.
  final List<RecouvrementSimulationRow> rows;

  /// Groupes qui passeraient **sous le seuil d'ingérabilité**.
  final List<String?> critical;

  /// Recettes **déjà encaissées** des visés, qu'un renvoi rendrait sans objet.
  final MoneyBag lost;

  /// Créances **abandonnées** : le reste dû des visés. Ne s'additionne jamais
  /// avec [lost] — l'une est de l'argent reçu, l'autre de l'argent jamais venu.
  final MoneyBag missing;

  const RecouvrementSimulation({
    required this.headcount,
    required this.targeted,
    required this.rows,
    required this.critical,
    required this.lost,
    required this.missing,
  });

  static const empty = RecouvrementSimulation(
    headcount: 0,
    targeted: 0,
    rows: <RecouvrementSimulationRow>[],
    critical: <String?>[],
    lost: MoneyBag.empty,
    missing: MoneyBag.empty,
  );

  int get remainingHeadcount => headcount - targeted;

  /// Part de l'effectif conservée **sur toute la page**.
  ///
  /// Recalculée sur la somme des groupes, **jamais moyennée** sur leurs
  /// pourcentages : une classe de trois pèserait alors autant qu'une de
  /// quarante.
  int get keptPercent =>
      headcount <= 0 ? 100 : ((remainingHeadcount * 100) / headcount).round();

  bool get isEmpty => headcount == 0;

  @override
  List<Object?> get props => [
    headcount,
    targeted,
    rows,
    critical,
    lost,
    missing,
  ];
}

/// Chiffre le coût d'un renvoi, **sans rien écrire**.
///
/// Pur et synchrone : la spec exige que le curseur de seuil « se sente
/// immédiat », donc aucun `Future` ne traverse ce calcul.
class RecouvrementSimulationProjector {
  const RecouvrementSimulationProjector._();

  /// [criticalPercent] : sous cette part conservée, un groupe est dit
  /// ingérable. [threshold] n'est lu que pour [RecouvrementCriterion.belowThreshold].
  /// [rate] sert à convertir un plancher quand la sélection mêle deux devises —
  /// **arbitrage, jamais montant affiché**. `null`, le critère du plancher ne
  /// vise personne plutôt que de comparer des unités qui ne se comparent pas.
  static RecouvrementSimulation project(
    List<LocalRecoveryLine> lines, {
    required RecouvrementCriterion criterion,
    required int criticalPercent,
    Money? threshold,
    ExchangeRate? rate,
  }) {
    if (lines.isEmpty) return RecouvrementSimulation.empty;

    final headcountBy = <String?, int>{};
    final targetedBy = <String?, int>{};
    var targeted = 0;
    var lost = MoneyBag.empty;
    var missing = MoneyBag.empty;

    for (final line in lines) {
      final level = line.schoolLevelId;
      headcountBy[level] = (headcountBy[level] ?? 0) + 1;
      if (!_targets(line, criterion, threshold, rate)) continue;

      targetedBy[level] = (targetedBy[level] ?? 0) + 1;
      targeted++;
      lost = lost + line.paidTotal;
      missing = missing + line.remaining;
    }

    final rows =
        [
          for (final entry in headcountBy.entries)
            RecouvrementSimulationRow(
              schoolLevelId: entry.key,
              headcount: entry.value,
              targeted: targetedBy[entry.key] ?? 0,
            ),
        ]..sort((a, b) {
          // Comparaison en produits croisés d'entiers, jamais sur `keptPercent` :
          // celui-ci est arrondi pour l'affichage et rendrait ex æquo deux
          // groupes à 54,4 % et 54,8 %.
          final byKept = (a.remainingHeadcount * b.headcount).compareTo(
            b.remainingHeadcount * a.headcount,
          );
          if (byKept != 0) return byKept;
          return (a.schoolLevelId ?? '').compareTo(b.schoolLevelId ?? '');
        });

    return RecouvrementSimulation(
      headcount: lines.length,
      targeted: targeted,
      rows: rows,
      critical: [
        for (final row in rows)
          if (row.keptPercent < criticalPercent) row.schoolLevelId,
      ],
      lost: lost,
      missing: missing,
    );
  }

  /// Les lignes que le critère **vise** — la population exacte que l'écran
  /// vient d'afficher comme visée.
  ///
  /// Exposée pour la liste de relance : elle doit porter ces élèves-là, pas une
  /// seconde population recalculée autrement. C'est la même règle, appelée une
  /// seule fois de plus.
  static List<LocalRecoveryLine> targetsOf(
    List<LocalRecoveryLine> lines, {
    required RecouvrementCriterion criterion,
    Money? threshold,
    ExchangeRate? rate,
  }) => [
    for (final line in lines)
      if (_targets(line, criterion, threshold, rate)) line,
  ];

  static bool _targets(
    LocalRecoveryLine line,
    RecouvrementCriterion criterion,
    Money? threshold,
    ExchangeRate? rate,
  ) => switch (criterion) {
    RecouvrementCriterion.noPayment => line.status == StudentChargeStatus.due,
    RecouvrementCriterion.notSettled => line.status != StudentChargeStatus.paid,
    RecouvrementCriterion.belowThreshold => _belowThreshold(
      line,
      threshold,
      rate,
    ),
  };

  /// A versé **moins que le plancher**, tout ramené dans la devise du plancher.
  ///
  /// Sans plancher, personne n'est visé : un champ vide ne doit pas viser toute
  /// l'école. Sans taux et en présence d'une autre devise, personne non plus —
  /// comparer un franc à un dollar sans cours n'est pas un arbitrage prudent,
  /// c'est un chiffre inventé.
  static bool _belowThreshold(
    LocalRecoveryLine line,
    Money? threshold,
    ExchangeRate? rate,
  ) {
    if (threshold == null) return false;
    // `null` = une devise du sac ne se convertit pas : on renonce à viser cet
    // élève plutôt que de comparer des unités étrangères.
    final paid = RecouvrementPivot.inCurrency(
      line.paidTotal,
      threshold.currency,
      rate,
    );
    if (paid == null) return false;
    return paid < threshold.amountInCents;
  }
}
