import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_bucket.dart';
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
  /// [TillSummary.total] vaut toujours la somme des [TillBucket.total] — les
  /// deux sont repliés depuis les mêmes lignes journalières. C'est le seul
  /// contrôle de cohérence que le pilotage financier autorise (l'axe du
  /// recouvrement, lui, n'en est pas un).
  final List<TillBucket> buckets;

  const TillCurrencyBlock({
    required this.currency,
    required this.summary,
    required this.buckets,
  });

  /// Rien n'est entré dans cette devise sur la fenêtre.
  ///
  /// C'est **le cas le plus fréquent de l'onglet** : le serveur garde à zéro
  /// toute devise que l'école facture ou dans laquelle elle vend, et une
  /// journée creuse en francs rend un bloc entier de zéros. Sans cette
  /// distinction, l'écran affiche trois cartes à zéro et une barre plate là où
  /// une phrase suffit.
  bool get hasNoMovement => summary.total == 0;

  @override
  List<Object?> get props => [currency, summary, buckets];
}
