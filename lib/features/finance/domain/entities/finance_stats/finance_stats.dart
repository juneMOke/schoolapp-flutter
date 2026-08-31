import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_currency_block.dart';

/// Le tableau de bord financier — **un bloc complet par devise**.
///
/// Les indicateurs vivaient à la racine, sous une devise unique que le serveur
/// devait élire. Ils descendent d'un niveau : une école qui facture en dollars
/// et en francs n'a pas de chiffre d'encaissement unique, et les additionner
/// montrerait un nombre qui n'est l'argent de personne.
///
/// `context.currency` a disparu du contrat pour la même raison — ce front ne la
/// lisait déjà pas.
class FinanceStats extends Equatable {
  final StatsContext context;

  /// Ordonnés par code de devise. **Vide** quand aucun argent n'a circulé sur la
  /// fenêtre — et non un zéro dans une unité que personne n'a choisie : c'est un
  /// état vide, pas une erreur.
  final List<FinanceCurrencyBlock> byCurrency;

  const FinanceStats({required this.context, required this.byCurrency});

  @override
  List<Object?> get props => [context, byCurrency];
}
