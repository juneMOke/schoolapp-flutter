import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/recovery_currency_block.dart';

/// Le recouvrement de l'année scolaire courante — **un bloc complet par
/// devise**.
///
/// L'**état** du pilotage financier : ce qu'il reste à encaisser. Le **flux** —
/// ce qui est entré dans le tiroir — est l'autre écran, et il ne se lit pas à
/// la même échelle. Les deux ont vécu sous un seul endpoint, avec un sélecteur
/// de période commun : à la semaine, les échéances tombant en fin de mois,
/// l'attendu valait zéro et l'écran annonçait « 0 attendu » un jour de guichet
/// chargé.
///
/// Il n'y a donc **aucune fenêtre à choisir ici** : le recouvrement est un état,
/// il ne se lit qu'à l'échelle où les créances existent.
class FinanceRecovery extends Equatable {
  /// `period` y vaut toujours `"year"`, et les bornes sont celles de l'année
  /// scolaire.
  final StatsContext context;

  /// Ordonnés par code de devise. **Vide** seulement si l'école n'a ni grille
  /// tarifaire sur l'année ni mouvement — pas une erreur, un état vide.
  ///
  /// Une devise que l'école facture sans qu'un franc y ait circulé garde son
  /// bloc, **à zéro** : c'est [RecoveryCurrencyBlock.hasNoMovement] qui le dit,
  /// pas l'absence.
  final List<RecoveryCurrencyBlock> byCurrency;

  const FinanceRecovery({required this.context, required this.byCurrency});

  @override
  List<Object?> get props => [context, byCurrency];
}
