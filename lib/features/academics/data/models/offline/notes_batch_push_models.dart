import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_input_model.dart';

/// Enveloppe d'ingest d'un lot de notes (`POST /sync/academics/notes`, régime C).
/// `{authorId?, evaluationId, notes[]}`. Sert aussi de **payload d'outbox**. Le
/// serveur upsert chaque note (LWW) et renvoie un **outcome par ligne** — jamais
/// d'all-or-nothing : une note sur période close ne fait pas échouer le lot.
class NotesBatchPushRequestModel extends Equatable {
  final String evaluationId;
  final List<NoteInputModel> notes;

  /// Uid de l'auteur (ADR-010 D-05), figé à la saisie. Le serveur (garde A3)
  /// rejette 403 si `authorId ≠ uid` du JWT.
  final String? authorId;

  const NotesBatchPushRequestModel({
    required this.evaluationId,
    this.notes = const [],
    this.authorId,
  });

  factory NotesBatchPushRequestModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['notes'] as List<dynamic>?) ?? const [];
    return NotesBatchPushRequestModel(
      authorId: json['authorId'] as String?,
      evaluationId: json['evaluationId'] as String,
      notes: raw
          .map((e) => NoteInputModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
    'evaluationId': evaluationId,
    'notes': notes.map((n) => n.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory NotesBatchPushRequestModel.fromJsonString(String payload) =>
      NotesBatchPushRequestModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [evaluationId, notes, authorId];
}

/// Outcome serveur d'UNE note (clé = `studentId`).
///
/// `APPLIED` (retenue) | `SUPERSEDED` (un état serveur plus récent existait —
/// LWW perdu, mais succès) | `REJECTED` (rejet métier terminal). `reason` précise
/// un rejet : `PERIODE_CLOSE` (arbitrée serveur) | `INVALID` (validation).
class NoteOutcomeModel extends Equatable {
  final String studentId;
  final String outcome;
  final String? reason;
  final String? serverUpdatedAt;

  const NoteOutcomeModel({
    required this.studentId,
    required this.outcome,
    this.reason,
    this.serverUpdatedAt,
  });

  factory NoteOutcomeModel.fromJson(Map<String, dynamic> json) =>
      NoteOutcomeModel(
        studentId: json['studentId'] as String,
        outcome: (json['outcome'] as String?)?.toUpperCase() ?? 'UNKNOWN',
        reason: (json['reason'] as String?)?.toUpperCase(),
        serverUpdatedAt: json['serverUpdatedAt'] as String?,
      );

  bool get isApplied => outcome == 'APPLIED' || outcome == 'SUPERSEDED';
  bool get isRejected => outcome == 'REJECTED';

  @override
  List<Object?> get props => [studentId, outcome, reason, serverUpdatedAt];
}

/// Réponse du push d'un lot de notes : la liste d'outcomes par ligne + un
/// éventuel `serverUpdatedAt` de lot (fraîcheur). Parsing **tolérant** : une
/// ligne d'outcome malformée est ignorée (elle restera PENDING → re-poussée).
class NotesBatchResponseModel extends Equatable {
  final List<NoteOutcomeModel> outcomes;
  final String? serverUpdatedAt;

  const NotesBatchResponseModel({
    this.outcomes = const [],
    this.serverUpdatedAt,
  });

  factory NotesBatchResponseModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['outcomes'] as List<dynamic>?) ?? const [];
    final parsed = <NoteOutcomeModel>[];
    for (final e in raw) {
      try {
        parsed.add(NoteOutcomeModel.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Outcome illisible : ignoré (la note reste PENDING, re-poussée).
      }
    }
    return NotesBatchResponseModel(
      outcomes: parsed,
      serverUpdatedAt: json['serverUpdatedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [outcomes, serverUpdatedAt];
}
