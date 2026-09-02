import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model/fee_type_item_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model/finance_evolution_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model/finance_kpis_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/recovery_currency_block.dart';

/// Miroir de `RecoveryCurrencyStatsDto` — un bloc complet par devise.
class RecoveryCurrencyBlockModel {
  final String currency;
  final FinanceKpisModel kpis;
  final List<FeeTypeItemModel> byFeeCode;
  final FinanceEvolutionModel monthlyCollected;

  const RecoveryCurrencyBlockModel({
    required this.currency,
    required this.kpis,
    required this.byFeeCode,
    required this.monthlyCollected,
  });

  factory RecoveryCurrencyBlockModel.fromJson(Map<String, dynamic> json) {
    final axis = json['monthlyCollected'];
    return RecoveryCurrencyBlockModel(
      // Normalisée, jamais refusée : une devise que le serveur ajouterait avant
      // cette version du client ne doit pas faire échouer la lecture de tout le
      // tableau de bord.
      currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
      kpis: FinanceKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
      // Une section absente est un non-évènement : la répartition disparaît,
      // les indicateurs restent.
      byFeeCode: [
        for (final raw in (json['byFeeCode'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) FeeTypeItemModel.fromJson(raw),
      ],
      monthlyCollected: axis is Map<String, dynamic>
          ? FinanceEvolutionModel.fromJson(axis)
          : FinanceEvolutionModel.empty,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'kpis': kpis.toJson(),
    'byFeeCode': byFeeCode.map((item) => item.toJson()).toList(growable: false),
    'monthlyCollected': monthlyCollected.toJson(),
  };

  RecoveryCurrencyBlock toEntity() => RecoveryCurrencyBlock(
    currency: currency,
    kpis: kpis.toEntity(),
    byFeeCode: byFeeCode.map((item) => item.toEntity()).toList(growable: false),
    monthlyCollected: monthlyCollected.toEntity(),
  );
}
