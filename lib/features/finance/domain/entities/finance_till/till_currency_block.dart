import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_best_bucket.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_bucket.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_classroom_amount.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_summary.dart';

/// La caisse **d'une devise** : le résumé de la fenêtre, et son détail
/// intervalle par intervalle.
///
/// Un bloc complet et autonome par unité, jamais un total mêlé, et **aucune
/// conversion** — même règle que partout ailleurs dans le pilotage financier.
/// Deux blocs se regardent côte à côte ; ils ne s'additionnent pas, et surtout
/// pas dans le tiroir d'un caissier qui compte des billets.
class TillCurrencyBlock extends Equatable {
  final String currency;
  final TillSummary summary;

  /// Jamais vide côté serveur, **même sur une période d'un seul jour**, où le
  /// bloc porte cette journée-là : une réponse dont la forme change avec la
  /// période obligerait l'écran à tenir deux branches d'affichage.
  ///
  /// ⚠️ **[TillSummary.total] ne vaut PAS la somme des [TillBucket.total], et ce
  /// n'est pas un bug.** Le résumé porte sur la **fenêtre demandée** ; la série
  /// dessine **ce qu'il faut pour lire cette fenêtre**. Les deux coïncident sur
  /// semaine, mois et année — et divergent sur `day`, où le serveur trace sept
  /// jours (`début − 6 j`) pour une seule journée comptée : un chiffre du jour,
  /// seul, ne dit pas s'il est bon.
  ///
  /// Cette classe a affirmé l'inverse, et le présentait comme « le seul contrôle
  /// de cohérence que le pilotage financier autorise ». La règle avait cessé
  /// d'être vraie sans que rien ne le signale : trois tests la défendaient
  /// encore, verts, parce qu'aucune fixture n'exerçait la fenêtre `day`. **Ne
  /// pas rétablir ce contrôle** — il ferait échouer la journée, qui est la
  /// fenêtre par défaut de l'écran.
  ///
  /// Le total à afficher est donc **toujours** celui du résumé, jamais un repli
  /// sur la somme des barres : additionner les barres serait plus court, et faux
  /// d'un facteur sept le jour où on le lit le plus.
  final List<TillBucket> buckets;

  /// Les classes qui ont le plus alimenté cette caisse — **un palmarès de huit
  /// lignes au plus**, jamais un total.
  ///
  /// Vide quand rien n'est entré, ou quand rien n'est rattachable à une classe.
  final List<TillClassroomAmount> byClassroom;

  /// Ce qui est entré dans cette caisse **sans désigner ni élève ni classe**, en
  /// centimes — une vente boutique, typiquement.
  ///
  /// **Doit être annoncé à l'écran, sous peine de faire passer le classement pour
  /// un bug** : sans cette mention, la somme des huit lignes ne retombe pas sur
  /// le total de la caisse et le lecteur cherche l'erreur. Elle n'y est pas.
  final int unassignedAmount;

  /// L'intervalle le plus fort de la série, et sa part de ce qui est **dessiné**.
  ///
  /// `null` sur une caisse creuse : elle n'a pas de meilleur jour, et en désigner
  /// un ferait lire une pointe là où il n'y a rien. **Absent vaut masqué**, même
  /// doctrine que [TillSummary.trendPercent].
  final TillBestBucket? bestBucket;

  const TillCurrencyBlock({
    required this.currency,
    required this.summary,
    required this.buckets,
    this.byClassroom = const [],
    this.unassignedAmount = 0,
    this.bestBucket,
  });

  /// De l'argent est entré sans classe attribuable : la carte « Par classe » doit
  /// le dire, sinon son total paraît faux.
  bool get hasUnassigned => unassignedAmount > 0;

  /// Rien n'est entré dans cette devise sur la fenêtre.
  ///
  /// C'est **le cas le plus fréquent de l'onglet** : le serveur garde à zéro
  /// toute devise que l'école facture ou dans laquelle elle vend, et une
  /// journée creuse en francs rend un bloc entier de zéros. Sans cette
  /// distinction, l'écran affiche trois cartes à zéro et une barre plate là où
  /// une phrase suffit.
  bool get hasNoMovement => summary.total == 0;

  @override
  List<Object?> get props => [
    currency,
    summary,
    buckets,
    byClassroom,
    unassignedAmount,
    bestBucket,
  ];
}
