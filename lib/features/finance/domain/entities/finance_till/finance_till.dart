import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_currency_block.dart';

/// La caisse de la fenêtre — **un bloc complet par devise**, frais et ventes
/// boutique réunis.
///
/// Le **flux** du pilotage financier, exact complémentaire du recouvrement qui
/// en est l'**état** : ici rien n'est dû, rien n'est attendu, aucun taux n'est
/// calculé. Tout est déjà encaissé.
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

  /// Ordonnés par code de devise. Vide seulement si rien n'a circulé **et**
  /// qu'aucun catalogue ne déclare de devise. Une devise dormante garde son
  /// bloc, à zéro — c'est [TillCurrencyBlock.hasNoMovement] qui le dit.
  final List<TillCurrencyBlock> byCurrency;

  const FinanceTill({
    required this.context,
    required this.timeZone,
    required this.byCurrency,
  });

  /// Le fuseau est connu : la mention « journée à l'heure de l'école » a un
  /// contenu.
  bool get hasTimeZone => timeZone.isNotEmpty;

  @override
  List<Object?> get props => [context, timeZone, byCurrency];
}
