import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_money.dart';

/// Replier les créances d'un élève **sous leur nature** (GF-1).
///
/// Un minerval en sept tranches donnait sept lignes à la suite dans la fiche.
/// Ce qu'on veut lire d'abord, c'est « où en est cet élève sur le minerval »,
/// tranches confondues — la même question, et la même maille, que le Contrôle
/// des frais, dont l'agrégat joint par `fee_code`.
///
/// **Purement présentationnel.** Rien ici ne décide d'un encaissement : la
/// saisie coche des tranches, et c'est la créance qui reste l'unité d'argent.

/// La progression d'**une devise** dans un groupe.
///
/// Une devise, une jauge. C'est la conséquence directe de l'absence de total
/// sur [MoneyBag] : 425,00 $ et 90 000 FC ne font pas un pourcentage commun, et
/// une jauge unique en fabriquerait un que personne ne pourrait vérifier.
class ChargeProgress extends Equatable {
  /// Ce qui a été facturé dans cette devise.
  final Money expected;

  /// Ce qui a été payé, **composé** : miroir serveur + encaissements de ce poste
  /// pas encore remontés (FRONT §5).
  final Money paid;

  const ChargeProgress({required this.expected, required this.paid});

  /// Le remplissage de la barre, entre 0 et 1.
  ///
  /// Même règle que la ligne de tranche, délibérément recopiée plutôt
  /// qu'approchée : **rien d'attendu mais quelque chose de payé vaut 1**, parce
  /// qu'une barre vide sous un montant encaissé se lit comme un encaissement
  /// perdu.
  double get ratio {
    if (expected.amountInCents <= 0) {
      return paid.amountInCents > 0 ? 1 : 0;
    }
    return (paid.amountInCents / expected.amountInCents).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [expected, paid];
}

/// Une nature de frais, et les tranches que **cet élève** en porte.
class StudentChargeGroup extends Equatable {
  /// La nature — `TUITION`. Normalisée en majuscules : c'est la forme que sert
  /// le serveur, mais le grand-livre local porte des lignes que rien n'oblige à
  /// l'avoir fait, et deux casses feraient deux groupes de la même nature.
  final String feeCode;

  /// Les tranches, **dans l'ordre où le DAO les a servies** — `fee_code`, puis
  /// échéance, puis code de tarif. Ce plan ne re-trie rien : l'ordre des
  /// échéances est celui dans lequel une famille paie.
  final List<StudentCharge> charges;

  const StudentChargeGroup({required this.feeCode, required this.charges});

  /// Vrai quand la nature ne porte qu'une tranche pour cet élève.
  ///
  /// ⚠️ **Le compte est celui de l'ÉLÈVE, pas celui de la grille.** Le Contrôle
  /// des frais compte des lignes de grille ; ici on compte des créances. Un
  /// élève inscrit en cours d'année, ou porteur d'une réduction, n'en porte pas
  /// sept — annoncer le compte de la grille dans sa fiche décrirait un autre
  /// élève que celui qu'on regarde.
  bool get isSingleTranche => charges.length == 1;

  /// Le nombre de tranches portées.
  int get trancheCount => charges.length;

  MoneyBag get expected => charges.expectedBag;
  MoneyBag get paidTotal => charges.paidTotalBag;
  MoneyBag get remaining => charges.remainingBag;

  /// Un encaissement d'au moins une tranche n'est pas encore remonté (FRONT §5).
  bool get hasPendingPayment =>
      charges.any((charge) => charge.amountPaidPendingInCents > 0);

  /// Le statut du groupe, dérivé du **composé** — jamais de `charge.status`.
  ///
  /// `status` est le miroir serveur, et **rien ne le recalcule après un
  /// encaissement local** : dans la fenêtre où un versement n'est pas remonté,
  /// il dit encore « à régler » sur un frais que le guichet vient de solder.
  /// C'est FRONT §6/§8 : le reste composé décide, le miroir jamais.
  ///
  /// La dérivation porte sur la **nullité**, pas sur des sommes — c'est ce qui
  /// la rend juste sans additionner deux devises.
  ///
  /// L'ordre des trois cas est celui de `feeStatusFromAmounts`, et il est repris
  /// tel quel : un groupe dont **rien n'est attendu ni payé** est dit « à
  /// régler », comme la ligne le dit déjà aujourd'hui. Diverger ici ferait dire
  /// deux choses à l'en-tête et à sa tranche sur la même créance à zéro.
  StudentChargeStatus get status {
    final anyPaid = charges.any((charge) => charge.paidTotalInCents > 0);
    if (!anyPaid) return StudentChargeStatus.due;

    final settled = charges.every((charge) => charge.remainingInCents <= 0);
    return settled ? StudentChargeStatus.paid : StudentChargeStatus.partial;
  }

  /// Une entrée par devise, dans l'ordre de [MoneyBag] — donc le même que celui
  /// des montants affichés à côté.
  ///
  /// Construite depuis les deux sacs plutôt qu'en regroupant les créances à la
  /// main : les sacs normalisent déjà la devise et trient déjà, et deux
  /// regroupements du même jeu finiraient par diverger sur un cas de bord.
  List<ChargeProgress> get progressByCurrency {
    final paidByCurrency = {
      for (final entry in paidTotal.entries) entry.currency: entry,
    };
    return [
      for (final entry in expected.entries)
        ChargeProgress(
          expected: entry,
          paid: paidByCurrency[entry.currency] ?? Money(0, entry.currency),
        ),
    ];
  }

  @override
  List<Object?> get props => [feeCode, charges];
}

/// Replie une liste de créances en groupes, **sans en perdre aucune**.
///
/// L'ordre des groupes est celui de **première apparition**, et celui des
/// tranches à l'intérieur est celui reçu. Les deux viennent du DAO
/// (`ORDER BY sc.fee_code ASC, (due_at IS NULL) ASC, due_at ASC, …`), qui groupe
/// et date déjà : re-trier ici ajouterait une seconde autorité d'ordonnancement
/// pour n'en respecter aucune.
///
/// La fonction reste juste sur une entrée **non triée** — elle regroupe par
/// clé, pas par adjacence. C'est ce qui la rend utilisable si le chemin online
/// pur venait à servir un autre ordre.
List<StudentChargeGroup> groupChargesByFeeCode(
  Iterable<StudentCharge> charges,
) {
  // `LinkedHashMap` par défaut en Dart : l'ordre d'insertion des clés est
  // l'ordre de première apparition, et c'est exactement ce qu'on veut publier.
  final grouped = <String, List<StudentCharge>>{};
  for (final charge in charges) {
    final key = charge.feeCode.trim().toUpperCase();
    (grouped[key] ??= <StudentCharge>[]).add(charge);
  }

  return [
    for (final entry in grouped.entries)
      StudentChargeGroup(
        feeCode: entry.key,
        charges: List<StudentCharge>.unmodifiable(entry.value),
      ),
  ];
}
