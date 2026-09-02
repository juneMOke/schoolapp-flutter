import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_currency_block_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_imputation_model.dart';
import 'package:school_app_flutter/features/finance/data/models/stats_context_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';

/// Miroir de `FinanceTillStatsResponse` — `GET /api/v1/finance-stats/till`.
///
/// **Deux blocs, et aucune voie de lecture de secours.** `byCurrency[]` a été
/// remplacé par `encaisse[]` + `impute[]` ; garder un repli
/// `encaisse ?? byCurrency` ferait vivre deux contrats à la fois, et l'écran
/// afficherait sans le dire de l'imputé sous le mot « encaissé » — exactement
/// ce que la bascule corrige.
class FinanceTillResponseModel {
  final StatsContextModel context;

  /// Le fuseau de l'école. **Jamais deviné** : absent du fil, il reste vide, et
  /// l'écran tait la mention plutôt que d'affirmer un découpage de journée
  /// qu'il n'a pas reçu.
  final String timeZone;

  /// Ce qui est entré dans le tiroir, par devise **reçue**.
  final List<TillCurrencyBlockModel> encaisse;

  /// Ce que ces versements ont éteint, par devise de **créance**.
  final List<TillImputationModel> impute;

  const FinanceTillResponseModel({
    required this.context,
    required this.timeZone,
    required this.encaisse,
    required this.impute,
  });

  /// **`encaisse` absent lève, et c'est le point de conception du lot.** Le
  /// danger n'est pas le travail de bascule, il est dans le silence : une
  /// tolérance `?? const []` sur cette clé rendrait l'état vide — « aucun
  /// mouvement aujourd'hui » — à un caissier qui a le tiroir plein, et un
  /// serveur resté sur l'ancien contrat passerait pour une journée creuse. La
  /// même tolérance a masqué cinq noms devinés faux sur les réductions.
  ///
  /// `impute` cède, lui, à une liste vide : c'est la ventilation d'un chiffre,
  /// pas le chiffre du tiroir. Sans elle l'écran perd une section ; sans
  /// `encaisse` il perd son sens.
  factory FinanceTillResponseModel.fromJson(Map<String, dynamic> json) {
    final encaisse = json['encaisse'];
    if (encaisse is! List) {
      throw const FormatException(
        'Réponse caisse sans `encaisse[]` : contrat non tenu (le serveur '
        'sert-il encore `byCurrency[]` ?).',
      );
    }
    return FinanceTillResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      timeZone: ((json['timeZone'] as String?) ?? '').trim(),
      encaisse: [
        for (final raw in encaisse)
          if (raw is Map<String, dynamic>) TillCurrencyBlockModel.fromJson(raw),
      ],
      impute: [
        for (final raw in (json['impute'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) TillImputationModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'timeZone': timeZone,
    'encaisse': [for (final block in encaisse) block.toJson()],
    'impute': [for (final block in impute) block.toJson()],
  };

  FinanceTill toEntity() => FinanceTill(
    context: context.toEntity(),
    timeZone: timeZone,
    encaisse: [for (final block in encaisse) block.toEntity()],
    impute: [for (final block in impute) block.toEntity()],
  );
}
