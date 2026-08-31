import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_currency_block_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/stats_context_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_stats.dart';

class FinanceStatsResponseModel {
  final StatsContextModel context;

  /// Un bloc par devise, ordonnés par code. Vide = aucun argent n'a circulé.
  final List<FinanceCurrencyBlockModel> byCurrency;

  const FinanceStatsResponseModel({
    required this.context,
    required this.byCurrency,
  });

  factory FinanceStatsResponseModel.fromJson(Map<String, dynamic> json) {
    return FinanceStatsResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      // Absent ou vide : aucun argent sur la fenêtre. Le rendu est un état
      // vide, jamais une erreur — et surtout jamais un bloc à zéro dans une
      // devise inventée.
      byCurrency: [
        for (final raw in (json['byCurrency'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            FinanceCurrencyBlockModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'byCurrency': [for (final block in byCurrency) block.toJson()],
  };

  FinanceStats toEntity() => FinanceStats(
    context: context.toEntity(),
    byCurrency: [for (final block in byCurrency) block.toEntity()],
  );
}
