import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';

/// Les quatre chiffres de tête du tableau de bord : deux montants et deux
/// effectifs.
///
/// Dans cet ordre, et il n'est pas décoratif : **attendu**, **perçu**, puis
/// combien d'élèves n'ont rien payé et combien ont commencé. La distinction
/// entre « rien » et « partiel » est la seule qui compte pour la relance — un
/// élève qui a fait un geste ne se traite pas comme un élève absent du registre.
///
/// « Tout soldé » n'a pas de tuile propre : il se lit dans la sous-ligne du
/// perçu. Trois tuiles d'effectif pour une population qui n'en a que trois
/// états auraient dit deux fois la même chose.
class RecouvrementKeyFigures extends Equatable {
  /// Population **concernée** : le nombre de couples (élève, niveau) portant au
  /// moins une créance de la sélection.
  ///
  /// Jamais le nombre d'inscrits. Un élève sans créance de ces frais n'est pas
  /// un mauvais payeur, il n'est pas facturé — le compter au dénominateur
  /// ferait chuter le taux pour une raison étrangère au recouvrement
  /// (RECOUVREMENT_PLAN.md, invariant n° 4).
  final int total;

  /// Aucun versement, nulle part sur la sélection.
  final int none;

  /// Un geste a été fait, il reste quelque chose.
  final int partial;

  /// Plus rien à devoir sur aucune créance de la sélection.
  final int settled;

  /// Attendu **net**, par devise. Jamais un total unique : additionner des
  /// francs et des dollars écrirait un montant qui n'existe pas.
  final MoneyBag expected;

  /// Payé composé — miroir serveur **plus** les encaissements non remontés.
  final MoneyBag paid;

  /// Reste dû, planché créance par créance. **Ce n'est pas** `expected − paid` :
  /// la soustraction globale passe sous le vrai reste dès qu'un élève paie en
  /// trop sur un poste et rien sur un autre.
  final MoneyBag remaining;

  const RecouvrementKeyFigures({
    required this.total,
    required this.none,
    required this.partial,
    required this.settled,
    required this.expected,
    required this.paid,
    required this.remaining,
  });

  static const empty = RecouvrementKeyFigures(
    total: 0,
    none: 0,
    partial: 0,
    settled: 0,
    expected: MoneyBag.empty,
    paid: MoneyBag.empty,
    remaining: MoneyBag.empty,
  );

  bool get isEmpty => total == 0;

  /// Part de l'effectif concerné, arrondie à l'entier. `0` quand personne n'est
  /// concerné — jamais une division par zéro.
  int percentOf(int count) => total == 0 ? 0 : ((count * 100) / total).round();

  @override
  List<Object?> get props => [
    total,
    none,
    partial,
    settled,
    expected,
    paid,
    remaining,
  ];
}

/// Réduit les lignes du registre aux quatre chiffres de tête.
///
/// **Pur** : ne lit rien, n'appelle rien. On lui donne ce que le grand-livre a
/// rendu, il rend ce que l'écran affiche — ce qui le rend testable sans base ni
/// widget.
class RecouvrementKeyFiguresProjector {
  const RecouvrementKeyFiguresProjector._();

  static RecouvrementKeyFigures project(List<LocalRecoveryLine> lines) {
    if (lines.isEmpty) return RecouvrementKeyFigures.empty;

    var none = 0;
    var partial = 0;
    var settled = 0;
    var expected = MoneyBag.empty;
    var paid = MoneyBag.empty;
    var remaining = MoneyBag.empty;

    for (final line in lines) {
      switch (line.status) {
        case StudentChargeStatus.due:
          none++;
        case StudentChargeStatus.partial:
          partial++;
        case StudentChargeStatus.paid:
          settled++;
      }
      expected = expected + line.expected;
      paid = paid + line.paidTotal;
      remaining = remaining + line.remaining;
    }

    return RecouvrementKeyFigures(
      total: lines.length,
      none: none,
      partial: partial,
      settled: settled,
      expected: expected,
      paid: paid,
      remaining: remaining,
    );
  }
}
