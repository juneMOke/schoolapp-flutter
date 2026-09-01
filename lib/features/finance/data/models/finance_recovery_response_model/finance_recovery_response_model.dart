import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model/recovery_currency_block_model.dart';
import 'package:school_app_flutter/features/finance/data/models/stats_context_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';

/// Miroir de `FinanceRecoveryResponse` — `GET /api/v1/finance-stats/recovery`.
class FinanceRecoveryResponseModel {
  final StatsContextModel context;

  /// Un bloc par devise, ordonnés par code.
  ///
  /// **Vide n'est plus le cas courant.** Le serveur garde à zéro toute devise
  /// de la grille tarifaire ; la liste ne se vide que si l'école n'a ni grille
  /// sur l'année ni mouvement. L'écran a donc deux états à tenir, et non un.
  final List<RecoveryCurrencyBlockModel> byCurrency;

  const FinanceRecoveryResponseModel({
    required this.context,
    required this.byCurrency,
  });

  factory FinanceRecoveryResponseModel.fromJson(Map<String, dynamic> json) {
    return FinanceRecoveryResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      byCurrency: [
        for (final raw in (json['byCurrency'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            RecoveryCurrencyBlockModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'byCurrency': [for (final block in byCurrency) block.toJson()],
  };

  FinanceRecovery toEntity() => FinanceRecovery(
    context: context.toEntity(),
    byCurrency: [for (final block in byCurrency) block.toEntity()],
  );
}
