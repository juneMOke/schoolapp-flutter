import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/copie_log_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_codecs.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';

/// Corps de `PUT /sync/academics/evaluations/{id}/sujet` (`SujetSyncRequest`)
/// et **payload d'outbox** : le sujet entier, qui remplace le précédent.
///
/// [clientUpdatedAt] (epoch ms) est l'heure de l'enregistrement sur le poste —
/// l'arbitre du dernier enregistrement gagnant, et la garde de l'accusé local.
/// [maxPoints] est le maximum local au moment de l'enregistrement : égal à
/// celui du serveur, il ne change rien.
class SujetPushRequestModel extends Equatable {
  final String evaluationId;
  final String? authorId;
  final int clientUpdatedAt;
  final double? maxPoints;
  final EvaluationSujetRow sujet;

  const SujetPushRequestModel({
    required this.evaluationId,
    required this.clientUpdatedAt,
    required this.sujet,
    this.authorId,
    this.maxPoints,
  });

  /// Corps envoyé au serveur (sans l'id d'évaluation, porté par la route).
  Map<String, dynamic> toBody() => {
    'authorId': ?authorId,
    'clientUpdatedAt': EpochIsoHelper.toIso(clientUpdatedAt),
    'dureeMinutes': sujet.dureeMinutes,
    'programme': sujet.programme,
    'consignes': sujet.consignes,
    'maxPoints': ?maxPoints,
    'questions': SujetCodecs.questionsToJson(sujet.questions),
  };

  String toJsonString() => jsonEncode({
    'evaluationId': evaluationId,
    'clientUpdatedAtMs': clientUpdatedAt,
    ...toBody(),
  });

  factory SujetPushRequestModel.fromJsonString(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return SujetPushRequestModel(
      evaluationId: json['evaluationId'] as String,
      authorId: json['authorId'] as String?,
      clientUpdatedAt: (json['clientUpdatedAtMs'] as num).toInt(),
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      sujet: EvaluationSujetRow(
        dureeMinutes: (json['dureeMinutes'] as num?)?.toInt(),
        programme: SujetCodecs.programmeFromJson(json['programme']),
        consignes: json['consignes'] as String?,
        questions: SujetCodecs.questionsFromJson(json['questions']),
        updatedAt: (json['clientUpdatedAtMs'] as num).toInt(),
      ),
    );
  }

  @override
  List<Object?> get props => [
    evaluationId,
    authorId,
    clientUpdatedAt,
    maxPoints,
    sujet,
  ];
}

/// Corps de `POST /sync/academics/evaluations/{id}/copie-log`
/// (`CopieLogSyncRequest`) et payload d'outbox : une diffusion.
class CopieLogPushRequestModel extends Equatable {
  final String? authorId;
  final CopieLogRow entry;

  const CopieLogPushRequestModel({required this.entry, this.authorId});

  Map<String, dynamic> toBody() => {
    'authorId': ?authorId,
    'entry': {
      'id': entry.id,
      'kind': entry.kind,
      'canal': entry.canal,
      'corrige': entry.corrige,
      'occurredAt': EpochIsoHelper.toIso(entry.occurredAt),
    },
  };

  String toJsonString() =>
      jsonEncode({'evaluationId': entry.evaluationId, ...toBody()});

  factory CopieLogPushRequestModel.fromJsonString(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final e = json['entry'] as Map<String, dynamic>;
    return CopieLogPushRequestModel(
      authorId: json['authorId'] as String?,
      entry: CopieLogRow(
        id: e['id'] as String,
        evaluationId: json['evaluationId'] as String,
        kind: e['kind'] as String,
        canal: e['canal'] as String?,
        corrige: e['corrige'] as bool? ?? false,
        occurredAt: DateTime.parse(
          e['occurredAt'] as String,
        ).millisecondsSinceEpoch,
      ),
    );
  }

  @override
  List<Object?> get props => [authorId, entry];
}

/// Réponse de `POST …/publications/{kind}` (`PublicationState`) ; [etat] nul
/// si le corps est illisible.
class PublicationStateModel {
  final PublicationEtat? etat;

  const PublicationStateModel(this.etat);

  factory PublicationStateModel.fromJson(Map<String, dynamic> json) =>
      PublicationStateModel(SujetCodecs.etatFromJson(json));
}
