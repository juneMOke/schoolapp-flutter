import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/fee_type_item.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_kpis.dart';

/// Le recouvrement **d'une seule devise** : où en est l'école de l'argent
/// qu'elle doit encaisser cette année, poste par poste, mois par mois.
///
/// Autonome à dessein : un écran qui n'affiche qu'une unité lit un bloc et n'a
/// besoin de rien d'autre.
///
/// **Aucune conversion, jamais.** Convertir demanderait un taux ; un taux bouge,
/// et un chiffre de pilotage qui bouge alors qu'aucun argent n'a bougé ne se lit
/// plus. Les blocs se regardent côte à côte, ils ne s'additionnent pas.
class RecoveryCurrencyBlock extends Equatable {
  final String currency;
  final FinanceKpis kpis;

  /// Seuls les postes facturés ou encaissés **dans cette devise**, triés par
  /// attendu décroissant — les postes qui pèsent d'abord, et un ordre qui ne se
  /// remanie pas d'un rafraîchissement à l'autre. Un même code facturé dans deux
  /// unités apparaît dans les deux blocs, avec son montant propre à chacun : ce
  /// n'est pas un doublon.
  final List<FeeTypeItem> byFeeCode;

  /// **Même axe du temps dans tous les blocs** — grain, clés de compartiment et
  /// `currentBucketIndex` identiques — pour que deux devises se comparent
  /// compartiment par compartiment. Seules les valeurs diffèrent.
  ///
  /// Ce qui autorise à **empiler** les graphiques, jamais à les superposer sur
  /// un même axe vertical : l'écart d'échelle entre le franc et le dollar est
  /// de ×2 800, et une courbe écraserait l'autre.
  final FinanceEvolution monthlyCollected;

  const RecoveryCurrencyBlock({
    required this.currency,
    required this.kpis,
    required this.byFeeCode,
    required this.monthlyCollected,
  });

  /// Rien n'a été facturé **ni** encaissé dans cette devise sur l'année.
  ///
  /// Le serveur garde à zéro toute devise de la grille tarifaire : son absence
  /// se lirait comme une école qui aurait cessé de facturer dedans. C'est donc
  /// ici, et non sur une liste vide, que se décide l'affichage d'un « aucun
  /// mouvement » — quatre cartes à zéro et deux graphiques plats ne disent pas
  /// la même chose qu'une phrase.
  ///
  /// ⚠️ Un bloc `expected > 0, collected == 0` **n'est pas** sans mouvement :
  /// il porte une créance entière à recouvrer, et c'est précisément ce qu'un
  /// écran de recouvrement doit montrer.
  bool get hasNoMovement => kpis.expected == 0 && kpis.collected == 0;

  @override
  List<Object?> get props => [currency, kpis, byFeeCode, monthlyCollected];
}
