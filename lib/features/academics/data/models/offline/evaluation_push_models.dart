import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';

/// Enveloppe d'ingest d'une évaluation (`POST /sync/academics/evaluations`,
/// régime A) : `{authorId?, evaluation}`. Sert aussi de **payload d'outbox**
/// (`toJsonString`/`fromJsonString`). Le serveur applique `ON CONFLICT (id) DO
/// NOTHING` (idempotent sur l'uuid client) : 201 créée ≡ 200 rejeu, les deux
/// succès.
class EvaluationPushRequestModel extends Equatable {
  final EvaluationInputModel evaluation;

  /// Uid de l'auteur (ADR-010 D-05), figé à la saisie. Le serveur (garde A3)
  /// rejette 403 si `authorId ≠ uid` du JWT. `null` = session héritée sans uid.
  final String? authorId;

  const EvaluationPushRequestModel({required this.evaluation, this.authorId});

  factory EvaluationPushRequestModel.fromJson(Map<String, dynamic> json) =>
      EvaluationPushRequestModel(
        authorId: json['authorId'] as String?,
        evaluation: EvaluationInputModel.fromJson(
          json['evaluation'] as Map<String, dynamic>,
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
    'evaluation': evaluation.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory EvaluationPushRequestModel.fromJsonString(String payload) =>
      EvaluationPushRequestModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [evaluation, authorId];
}

/// Réponse du serveur au push d'une évaluation. On ne consomme que ce qui sert
/// au réalignement local : l'id canonique + `serverUpdatedAt` (visibilité). Le
/// `serverUpdatedAt` peut arriver au niveau racine ou dans l'objet évaluation
/// (tolérance de contrat).
class EvaluationPushResponseModel extends Equatable {
  final String id;

  /// ISO-8601 (temps de visibilité serveur), ou null si le contrat ne le porte
  /// pas — le réalignement pose alors SYNCED sans `server_updated_at`.
  final String? serverUpdatedAt;

  const EvaluationPushResponseModel({required this.id, this.serverUpdatedAt});

  factory EvaluationPushResponseModel.fromJson(Map<String, dynamic> json) {
    final nested = json['evaluation'];
    final evalJson = nested is Map<String, dynamic> ? nested : json;
    return EvaluationPushResponseModel(
      id: (evalJson['id'] ?? json['id']) as String? ?? '',
      serverUpdatedAt:
          (json['serverUpdatedAt'] ?? evalJson['serverUpdatedAt']) as String?,
    );
  }

  @override
  List<Object?> get props => [id, serverUpdatedAt];
}
