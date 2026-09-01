import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_currency_block_model.dart';
import 'package:school_app_flutter/features/finance/data/models/stats_context_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';

/// Miroir de `FinanceTillStatsResponse` — `GET /api/v1/finance-stats/till`.
class FinanceTillResponseModel {
  final StatsContextModel context;

  /// Le fuseau de l'école. **Jamais deviné** : absent du fil, il reste vide, et
  /// l'écran tait la mention plutôt que d'affirmer un découpage de journée
  /// qu'il n'a pas reçu.
  final String timeZone;

  final List<TillCurrencyBlockModel> byCurrency;

  const FinanceTillResponseModel({
    required this.context,
    required this.timeZone,
    required this.byCurrency,
  });

  factory FinanceTillResponseModel.fromJson(Map<String, dynamic> json) {
    return FinanceTillResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      timeZone: ((json['timeZone'] as String?) ?? '').trim(),
      byCurrency: [
        for (final raw in (json['byCurrency'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) TillCurrencyBlockModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'timeZone': timeZone,
    'byCurrency': [for (final block in byCurrency) block.toJson()],
  };

  FinanceTill toEntity() => FinanceTill(
    context: context.toEntity(),
    timeZone: timeZone,
    byCurrency: [for (final block in byCurrency) block.toEntity()],
  );
}
