import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/fee_type_distribution_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_evolution_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_kpis_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_currency_block.dart';

/// Miroir de `FinanceCurrencyStatsDto` — un bloc complet par devise.
class FinanceCurrencyBlockModel {
  final String currency;
  final FinanceKpisModel kpis;
  final FinanceEvolutionModel evolution;
  final FeeTypeDistributionModel distributionByFeeType;

  const FinanceCurrencyBlockModel({
    required this.currency,
    required this.kpis,
    required this.evolution,
    required this.distributionByFeeType,
  });

  factory FinanceCurrencyBlockModel.fromJson(Map<String, dynamic> json) =>
      FinanceCurrencyBlockModel(
        // Normalisée, jamais refusée : une devise que le serveur ajouterait
        // avant cette version du client ne doit pas faire échouer la lecture de
        // tout le tableau de bord.
        currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
        kpis: FinanceKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
        evolution: FinanceEvolutionModel.fromJson(
          json['evolution'] as Map<String, dynamic>,
        ),
        distributionByFeeType: FeeTypeDistributionModel.fromJson(
          json['distributionByFeeType'] as Map<String, dynamic>,
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'kpis': kpis.toJson(),
    'evolution': evolution.toJson(),
    'distributionByFeeType': distributionByFeeType.toJson(),
  };

  FinanceCurrencyBlock toEntity() => FinanceCurrencyBlock(
    currency: currency,
    kpis: kpis.toEntity(),
    evolution: evolution.toEntity(),
    distributionByFeeType: distributionByFeeType.toEntity(),
  );
}
