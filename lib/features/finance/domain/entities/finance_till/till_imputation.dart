import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_fee_code_amount.dart';

/// Ce que les versements de la fenêtre ont **éteint**, dans une devise de
/// **créance**, ventilé par nature de frais.
///
/// Le pendant de l'encaisse, dans l'autre unité. Un parent qui règle 50 USD en
/// tendant 115 000 FC fait peser le même versement dans le bloc **CDF** de
/// l'encaisse et dans le bloc **USD** de l'imputation : les deux tableaux ne
/// s'additionnent pas, et ne se recoupent pas ligne à ligne. Convertir l'un
/// vers l'autre serait possible — le taux est gelé sur chaque ligne
/// d'encaissement — mais fabriquerait des montants que personne ne peut
/// recompter à la main.
///
/// La boutique n'y figure jamais : une vente comptant n'est imputée sur aucune
/// créance.
class TillImputation extends Equatable {
  /// Devise de la **créance**, jamais celle qui a été tendue au guichet.
  final String currency;

  /// Somme exacte des [byFeeCode], en centimes. Le bloc est cohérent en
  /// interne : ce total retombe toujours sur ce qu'il affiche dessous.
  final int total;

  /// Ventilation par nature de frais, montant décroissant, code en départage.
  final List<TillFeeCodeAmount> byFeeCode;

  const TillImputation({
    required this.currency,
    required this.total,
    required this.byFeeCode,
  });

  @override
  List<Object?> get props => [currency, total, byFeeCode];
}
