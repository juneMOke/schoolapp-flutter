import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_crossed.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_currency_block.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_imputation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_summary.dart';

/// La caisse de la fenêtre — **deux blocs qui ne se comptent pas dans la même
/// unité**.
///
/// Le **flux** du pilotage financier, exact complémentaire du recouvrement qui
/// en est l'**état** : ici rien n'est dû, rien n'est attendu. Tout est déjà
/// encaissé.
///
/// Les deux tableaux gardent les noms du contrat — `encaisse` et `impute` — et
/// ce n'est pas de la paresse : traduire ici obligerait à retenir deux
/// vocabulaires pour la même chose, et c'est exactement là que se perdent les
/// noms devinés.
class FinanceTill extends Equatable {
  /// `period` y porte la fenêtre demandée, et `periodStart` / `periodEnd` ses
  /// bornes. **Ce sont elles qu'on affiche** — jamais des bornes recalculées
  /// côté tablette.
  final StatsContext context;

  /// Le fuseau dans lequel la journée commence et finit — `Africa/Kinshasa`
  /// aujourd'hui. **Ce n'est pas décoratif** : sans lui, on ne sait pas de
  /// quelles vingt-quatre heures parle un total, ni pourquoi un découpage local
  /// ne retombe pas dessus. Un encaissement sonné à 00 h 20 au guichet porte un
  /// instant serveur de 23 h 20 Z la veille.
  ///
  /// Vide si le serveur ne l'envoie pas : l'écran tait alors la mention plutôt
  /// que d'affirmer un fuseau qu'il aurait deviné.
  final String timeZone;

  /// Ce qui est **physiquement entré dans le tiroir**, un bloc par devise
  /// **reçue**, ordonné par code de devise. C'est ce que le caissier compare à
  /// son tiroir le soir, frais et boutique réunis.
  ///
  /// Vide seulement si rien n'a circulé **et** qu'aucun catalogue ne déclare de
  /// devise. Une devise dormante garde son bloc, à zéro — c'est
  /// [TillCurrencyBlock.hasNoMovement] qui le dit.
  final List<TillCurrencyBlock> encaisse;

  /// Ce que ces mêmes versements ont **éteint**, un bloc par devise de
  /// **créance**. C'est ce que la direction lit.
  ///
  /// **Ne s'additionne jamais avec [encaisse]**, et ne se recoupe pas ligne à
  /// ligne : depuis qu'un parent peut régler 50 USD en tendant 115 000 FC, un
  /// même versement pèse dans le bloc CDF de l'un et le bloc USD de l'autre.
  final List<TillImputation> impute;

  /// Le nombre de reçus de la fenêtre, **toutes caisses confondues**.
  ///
  /// **Le seul agrégat légitimement inter-devises de l'écran** — parce que c'est
  /// un compteur et non un montant. Chaque reçu y compte **une seule fois**,
  /// quel que soit le nombre de caisses qu'il a alimentées.
  ///
  /// Il ne vaut donc pas la somme des [TillSummary.receiptCount] : un versement
  /// payé moitié-moitié entre dans les deux compteurs de caisse et une seule fois
  /// ici. La tuile qui le porte doit l'annoncer, faute de quoi « 40 $ + 35 FC »
  /// au-dessus de « 70 reçus émis » a raison deux fois et paraît faux.
  ///
  /// Un « reçu » est **un encaissement**, qu'une pièce ait été scellée ou non :
  /// compter les seuls versements portant un numéro diviserait un mois de reprise
  /// du cahier par 2 au lieu de 91.
  final int receiptsIssued;

  /// Les paiements croisés de la fenêtre — ceux qui ont réglé un frais fixé dans
  /// une autre devise que celle tendue.
  ///
  /// Toujours présent, éventuellement à zéro : l'encart de lecture garde sa
  /// formulation de repli plutôt que de disparaître, parce qu'une carte absente
  /// laisse croire qu'on a oublié de regarder.
  final TillCrossed crossed;

  const FinanceTill({
    required this.context,
    required this.timeZone,
    required this.encaisse,
    required this.impute,
    this.receiptsIssued = 0,
    this.crossed = const TillCrossed(count: 0, amounts: [], rateMicros: []),
  });

  /// Le fuseau est connu : la mention « journée à l'heure de l'école » a un
  /// contenu.
  bool get hasTimeZone => timeZone.isNotEmpty;

  /// Aucun reçu sur la fenêtre, dans aucune devise — l'état vide **global**,
  /// distinct de la caisse vide dont l'autre a travaillé.
  bool get hasNoReceipts => receiptsIssued == 0;

  @override
  List<Object?> get props => [
    context,
    timeZone,
    encaisse,
    impute,
    receiptsIssued,
    crossed,
  ];
}
