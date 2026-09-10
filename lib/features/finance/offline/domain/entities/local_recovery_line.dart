import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';

/// Position d'un élève sur **un frais de la sélection**, dans une devise.
///
/// Enveloppe un [FeeChargePosition] au lieu de redéclarer ses champs : le payé
/// composé, le reste planché et les règles d'arithmétique restent dits une seule
/// fois, là-bas. On n'ajoute ici que le [feeCode], dont le tableau de bord a
/// besoin pour le taux **par frais** — l'écran de contrôle, lui, n'interrogeant
/// qu'une nature à la fois, n'avait aucune raison de la porter.
class RecoveryChargePosition extends Equatable {
  /// Nature du frais (`fee_code`), jamais un libellé : l'écran est école-wide,
  /// et deux niveaux nomment la même nature différemment.
  final String feeCode;

  /// Position financière, à la lettre de l'écran de contrôle.
  final FeeChargePosition position;

  const RecoveryChargePosition({required this.feeCode, required this.position});

  String get currency => position.currency;

  int get expectedInCents => position.expectedInCents;

  /// Miroir serveur **plus** les encaissements de ce poste non encore remontés.
  int get paidTotalInCents => position.paidTotalInCents;

  /// `max(0, attendu − payé)`, **par créance**.
  int get remainingInCents => position.remainingInCents;

  @override
  List<Object?> get props => [feeCode, position];
}

/// Position d'un élève sur **une sélection de frais**, rattachée au niveau que
/// portent ses créances — la maille du tableau de bord du Recouvrement.
///
/// ## Pourquoi une ligne par (élève, niveau) et non par élève
///
/// Un élève qui change de niveau en cours d'année porte des créances sur les
/// deux, et il doit bel et bien à chacun. Grouper par élève seul ferait fondre
/// un niveau dans l'autre ; grouper par (élève, niveau) maintient l'invariant
/// qui fait tenir l'écran : **le total de la page est la somme de ses groupes**.
/// Le même élève compte alors deux fois, et c'est exact.
///
/// ## Le statut est emprunté, jamais recalculé
///
/// [status] délègue à [LocalFeeChargeAggregate], la règle qui sert déjà l'écran
/// de contrôle. C'est ce qui rend impossible que les deux écrans du module se
/// contredisent sur le même élève (RECOUVREMENT_PLAN.md, invariant n° 1).
///
/// ⚠️ L'agrégat reçoit ici **plusieurs positions d'une même devise** — une par
/// frais retenu — là où l'écran de contrôle ne lui en passe jamais qu'une.
/// Cela reste exact, et c'est structurel : sa règle plancher le reste
/// **position par position** avant de conclure, donc un trop-perçu sur la
/// scolarité n'efface pas l'impayé des fournitures. C'est l'invariant n° 5, et
/// c'est précisément ce que le back a dû nous rappeler : une somme de maxima
/// n'est pas le maximum de la somme.
class LocalRecoveryLine extends Equatable {
  /// Niveau porté par les créances de cet élève.
  ///
  /// ⚠️ **Nullable, et la ligne est conservée quand même.** `school_level_id`
  /// est nullable au schéma : une créance *ad hoc*, ou descendue d'un serveur
  /// qui ne renseignait pas encore la colonne, n'en a pas. La filtrer au SQL
  /// ferait disparaître des élèves **sans rien dire**, et le total de l'école
  /// cesserait d'être la somme de ses niveaux.
  final String? schoolLevelId;

  final String studentId;

  /// Une entrée par `(fee_code, devise)`, triée par code de frais puis devise.
  /// **Jamais vide** : un élève sans créance sur la sélection n'a pas de ligne
  /// du tout — « aucun paiement » n'est pas « aucune créance ».
  final List<RecoveryChargePosition> charges;

  const LocalRecoveryLine({
    required this.schoolLevelId,
    required this.studentId,
    required this.charges,
  });

  /// Statut de l'élève sur **toute la sélection** — emprunté à la règle du
  /// module, jamais réécrit.
  ///
  /// `rien` si aucun versement nulle part · `soldé` si plus rien ne reste sur
  /// aucune créance · `partiel` sinon. Les trois sont exclusifs et exhaustifs.
  StudentChargeStatus get status => LocalFeeChargeAggregate(
    studentId: studentId,
    positions: [for (final charge in charges) charge.position],
  ).status;

  /// Attendu de l'élève sur la sélection, **par devise**.
  MoneyBag get expected => MoneyBag.sumBy(
    charges,
    (c) => Money.parse(c.expectedInCents, c.currency),
  );

  /// Payé composé sur la sélection, **par devise**. Jamais plafonné : un
  /// trop-perçu remonte tel quel, et c'est au client de plancher le reste.
  MoneyBag get paidTotal => MoneyBag.sumBy(
    charges,
    (c) => Money.parse(c.paidTotalInCents, c.currency),
  );

  /// Reste dû sur la sélection, **par devise**, planché créance par créance.
  MoneyBag get remaining => MoneyBag.sumBy(
    charges,
    (c) => Money.parse(c.remainingInCents, c.currency),
  );

  @override
  List<Object?> get props => [schoolLevelId, studentId, charges];
}
