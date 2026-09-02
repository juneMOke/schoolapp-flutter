import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_currency_block.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_imputation.dart';

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

  const FinanceTill({
    required this.context,
    required this.timeZone,
    required this.encaisse,
    required this.impute,
  });

  /// Le fuseau est connu : la mention « journée à l'heure de l'école » a un
  /// contenu.
  bool get hasTimeZone => timeZone.isNotEmpty;

  @override
  List<Object?> get props => [context, timeZone, encaisse, impute];
}
