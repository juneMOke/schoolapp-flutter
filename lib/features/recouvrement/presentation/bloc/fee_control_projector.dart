import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

/// Part de [count] sur [total], en pourcentage entier **prêt à afficher**.
///
/// ⚠️ **100 % ne s'écrit que si personne ne reste, 0 % que si personne n'y
/// est.** Un arrondi ordinaire annonce « 100 % » sur 249 soldés pour 250
/// concernés : le préfet lit « niveau en règle » et le dernier débiteur
/// disparaît du radar. Symétriquement, un seul élève soldé sur 400 ne doit pas
/// s'annoncer « 0 % » — c'est effacer le seul qui a payé. D'où le clamp à
/// [1, 99] entre les deux bornes, qui restent exactes.
///
/// Une seule fonction pour tout le module : le bandeau du contrôle et le
/// classement du tableau de bord doivent arrondir pareil, sans quoi le même
/// niveau s'annonce à 100 % sur un écran et à 99 % sur l'autre.
int feeSharePercent(int count, int total) {
  if (total <= 0 || count <= 0) return 0;
  if (count >= total) return 100;
  return (count * 100 / total).round().clamp(1, 99);
}

/// Répartition des élèves d'une classe sur les frais contrôlés.
///
/// Comptée sur la population **concernée** (ceux qui portent au moins une
/// créance des frais retenus), pas sur la liste affichée : les compteurs doivent
/// répondre « où en est la classe » même quand le tableau ne montre qu'une
/// situation. Sans quoi, filtrer sur « Tout soldé » afficherait « 12 soldés,
/// 0 partiel, 0 rien » — la tuile active n'afficherait que son propre reflet.
class FeeControlBreakdown extends Equatable {
  final int settled;
  final int partial;
  final int none;

  const FeeControlBreakdown({
    this.settled = 0,
    this.partial = 0,
    this.none = 0,
  });

  int get total => settled + partial + none;

  bool get isEmpty => total == 0;

  /// Part d'élèves **en ordre**, en pourcentage entier prêt à afficher
  /// (cf. [feeSharePercent]).
  ///
  /// Pour **comparer** deux répartitions, ne pas passer par ce nombre : il crée
  /// des ex æquo qui n'existent pas (99,4 % et 99,8 % y valent tous deux 99).
  /// Le classement du tableau de bord compare les fractions exactes.
  int get settledPercent => feeSharePercent(settled, total);

  @override
  List<Object?> get props => [settled, partial, none];
}

/// Résultat du croisement élèves × créances, avant et après le filtre.
///
/// Les deux listes sont renvoyées parce que leur ÉCART est une information :
/// une classe peuplée dont aucun élève ne porte les frais ([charged] vide) est
/// un constat très différent d'une classe dont personne ne correspond à la
/// situation demandée ([filtered] vide, [charged] non). L'état vide de l'écran
/// s'appuie dessus pour ne pas envoyer chercher une erreur de saisie là où il
/// n'y a qu'une grille tarifaire incomplète.
class FeeControlJoin {
  /// Élèves portant réellement une créance des frais retenus.
  final List<FeeControlRow> charged;

  /// Parmi eux, ceux qui correspondent à la situation demandée — **triés du
  /// moins avancé au plus avancé**.
  final List<FeeControlRow> filtered;

  /// Répartition de [charged] par statut, que le filtre ne doit pas réduire.
  final FeeControlBreakdown breakdown;

  /// Attendu et encaissé de **toute la classe** sur les frais retenus, par
  /// devise. Jamais un total unique : additionner des francs et des dollars
  /// écrirait un montant qui n'existe pas.
  final MoneyBag expected;
  final MoneyBag collected;

  const FeeControlJoin({
    required this.charged,
    required this.filtered,
    required this.breakdown,
    required this.expected,
    required this.collected,
  });

  static const empty = FeeControlJoin(
    charged: <FeeControlRow>[],
    filtered: <FeeControlRow>[],
    breakdown: FeeControlBreakdown(),
    expected: MoneyBag.empty,
    collected: MoneyBag.empty,
  );
}

/// Croisement **pur** des élèves inscrits et de leur position sur une sélection
/// de frais. Ne lit rien, n'appelle rien : testable sans base ni widget.
class FeeControlProjector {
  const FeeControlProjector._();

  /// Apparie chaque résumé à sa ligne de registre, compte la classe entière,
  /// puis applique la situation demandée et ordonne le travail.
  ///
  /// Un élève **sans créance est écarté** : « aucun paiement » n'est pas
  /// « aucune créance ». Il n'est pas concerné par ces frais, l'afficher à zéro
  /// le ferait passer pour un mauvais payeur.
  static FeeControlJoin join({
    required List<EnrollmentSummary> summaries,
    required List<LocalRecoveryLine> lines,
    required FeeControlPaymentFilter filter,
    Money? threshold,
    ExchangeRate? rate,
  }) {
    final byStudent = _mergeByStudent(lines);

    final charged = <FeeControlRow>[];
    var settled = 0;
    var partial = 0;
    var none = 0;
    var expected = MoneyBag.empty;
    var collected = MoneyBag.empty;

    for (final summary in summaries) {
      final line = byStudent[summary.student.id];
      if (line == null) continue;
      final row = FeeControlRow(summary: summary, line: line);
      charged.add(row);
      switch (row.status) {
        case StudentChargeStatus.paid:
          settled++;
        case StudentChargeStatus.partial:
          partial++;
        case StudentChargeStatus.due:
          none++;
      }
      expected = expected + row.expected;
      collected = collected + row.paid;
    }

    return FeeControlJoin(
      charged: charged,
      filtered: refilter(
        charged,
        filter: filter,
        threshold: threshold,
        rate: rate,
      ),
      breakdown: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
      expected: expected,
      collected: collected,
    );
  }

  /// Applique la situation et ordonne le travail, **sans rien relire**.
  ///
  /// Exposée parce qu'une tuile de compteur change de situation sans changer
  /// de périmètre : la population est déjà là, seule la coupe bouge. Relire la
  /// base à chaque clic ferait payer un aller-retour SQLCipher pour un filtre
  /// qui tient en mémoire.
  static List<FeeControlRow> refilter(
    List<FeeControlRow> charged, {
    required FeeControlPaymentFilter filter,
    Money? threshold,
    ExchangeRate? rate,
  }) => List<FeeControlRow>.unmodifiable(
    [
      for (final row in charged)
        if (row.matches(filter, threshold: threshold, rate: rate)) row,
    ]..sort((a, b) => _byProgress(a, b, rate)),
  );

  /// **Une ligne par élève**, quel que soit le nombre de niveaux qu'il porte.
  ///
  /// Le registre rend un couple (élève, niveau) — la maille du tableau de bord,
  /// où un élève qui change de niveau en cours d'année doit compter dans les
  /// deux. Ici la question est nominative : le même élève ne peut pas
  /// apparaître deux fois dans la liste d'appel de sa classe. On concatène donc
  /// ses créances, ce qui est exact : le statut se déduit ensuite de toutes ses
  /// positions, plancher par plancher.
  static Map<String, LocalRecoveryLine> _mergeByStudent(
    List<LocalRecoveryLine> lines,
  ) {
    final merged = <String, LocalRecoveryLine>{};
    for (final line in lines) {
      final previous = merged[line.studentId];
      merged[line.studentId] = previous == null
          ? line
          : LocalRecoveryLine(
              // Le niveau de la PREMIÈRE ligne rencontrée : l'écran est borné à
              // une classe, donc à un niveau, et cette valeur n'est plus lue que
              // pour mémoire.
              schoolLevelId: previous.schoolLevelId,
              studentId: line.studentId,
              charges: [...previous.charges, ...line.charges],
            );
    }
    return merged;
  }

  /// Du moins avancé au plus avancé, puis par nom — **déterministe**, pour que
  /// la même liste imprimée deux fois soit identique.
  ///
  /// ⚠️ Les lignes dont le taux est inconnu (deux devises, aucun cours) ferment
  /// la marche : elles ne peuvent pas être placées sur l'échelle de progression,
  /// et les mettre en tête ferait passer pour urgents des élèves peut-être à
  /// jour. Leur pastille de statut, elle, reste juste.
  static int _byProgress(FeeControlRow a, FeeControlRow b, ExchangeRate? rate) {
    final ra = a.ratePercent(rate);
    final rb = b.ratePercent(rate);
    if (ra != rb) {
      if (ra == null) return 1;
      if (rb == null) return -1;
      return ra.compareTo(rb);
    }
    final byName = a.summary.student.lastName.toLowerCase().compareTo(
      b.summary.student.lastName.toLowerCase(),
    );
    if (byName != 0) return byName;
    final byFirst = a.summary.student.firstName.toLowerCase().compareTo(
      b.summary.student.firstName.toLowerCase(),
    );
    return byFirst != 0 ? byFirst : a.studentId.compareTo(b.studentId);
  }
}
