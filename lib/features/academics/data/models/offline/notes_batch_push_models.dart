import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_input_model.dart';

/// Enveloppe d'ingest d'un lot de notes (`POST /sync/academics/notes`, régime
/// C) : `{authorId?, notes[]}` — chaque `NoteInputModel` porte son propre
/// `evaluationId` (contrat `NoteBatchSyncRequest`, pas de champ `evaluationId`
/// au niveau du lot). [evaluationId] reste un champ **local** (clé de
/// coalescing de l'outbox + garde de dépendance ÉVALUATION→NOTE), dérivé de la
/// première ligne à la reconstruction (`fromJson`) plutôt que sérialisé.
/// Sert aussi de **payload d'outbox** (`toJsonString`/`fromJsonString`). Le
/// serveur upsert chaque note (LWW) et renvoie un **outcome par ligne** —
/// jamais d'all-or-nothing : une note sur période close ne fait pas échouer
/// le lot.
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
    final notes = raw
        .map((e) => NoteInputModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return NotesBatchPushRequestModel(
      authorId: json['authorId'] as String?,
      evaluationId: notes.isNotEmpty ? notes.first.evaluationId : '',
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
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

/// État canonique serveur d'une note (`NoteSyncView` de l'ACK) — porté par un
/// outcome `APPLIED`/`SUPERSEDED`. Sert à réaligner le local sur l'état
/// serveur : sur un `SUPERSEDED`, la valeur poussée par ce client a PERDU le
/// LWW face à un état serveur plus récent — le local doit refléter ce dernier,
/// pas ce qui a été envoyé.
class NoteSyncViewModel extends Equatable {
  final String? id;
  final String? evaluationId;
  final String studentId;
  final String statut;
  final double? pointsObtenus;

  /// ISO-8601.
  final String? updatedAt;

  /// ISO-8601 — temps de visibilité serveur (curseur), distinct du `updatedAt`
  /// LWW.
  final String? serverUpdatedAt;

  const NoteSyncViewModel({
    this.id,
    this.evaluationId,
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  factory NoteSyncViewModel.fromJson(Map<String, dynamic> json) =>
      NoteSyncViewModel(
        id: json['id'] as String?,
        evaluationId: json['evaluationId'] as String?,
        studentId: json['studentId'] as String? ?? '',
        // Parsing tolérant (DF-I) : un statut inconnu/absent retombe sur
        // EN_ATTENTE plutôt que de faire échouer toute la ligne.
        statut: json['statut'] as String? ?? 'EN_ATTENTE',
        pointsObtenus: (json['pointsObtenus'] as num?)?.toDouble(),
        updatedAt: json['updatedAt'] as String?,
        serverUpdatedAt: json['serverUpdatedAt'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    evaluationId,
    studentId,
    statut,
    pointsObtenus,
    updatedAt,
    serverUpdatedAt,
  ];
}

/// Outcome serveur d'UNE ligne de note (clé = `studentId`) — `NoteLineOutcome`.
///
/// `APPLIED` (retenue) | `SUPERSEDED` (un état serveur plus récent existait —
/// LWW perdu, mais succès) | `REJECTED` (rejet métier terminal). `reason`
/// précise un rejet : `UNKNOWN_EVALUATION` | `PERIODE_CLOSE` (arbitrée
/// serveur) | `INVALID: …` | `EVALUATION_CONTEXT_UNAVAILABLE`. [note] porte
/// l'état canonique serveur — présent pour `APPLIED`/`SUPERSEDED`, absent pour
/// `REJECTED`.
class NoteOutcomeModel extends Equatable {
  final String studentId;
  final String? evaluationId;
  final String outcome;
  final String? reason;
  final NoteSyncViewModel? note;

  const NoteOutcomeModel({
    required this.studentId,
    this.evaluationId,
    required this.outcome,
    this.reason,
    this.note,
  });

  factory NoteOutcomeModel.fromJson(
    Map<String, dynamic> json,
  ) => NoteOutcomeModel(
    studentId: json['studentId'] as String,
    evaluationId: json['evaluationId'] as String?,
    // Champ wire réel : `status` (pas `outcome`) — `NoteLineOutcome.status`.
    outcome: (json['status'] as String?)?.toUpperCase() ?? 'UNKNOWN',
    // Texte libre serveur (ex. `INVALID: hors bornes`) — jamais muté.
    reason: json['reason'] as String?,
    note: json['note'] is Map<String, dynamic>
        ? NoteSyncViewModel.fromJson(json['note'] as Map<String, dynamic>)
        : null,
  );

  bool get isApplied => outcome == 'APPLIED' || outcome == 'SUPERSEDED';
  bool get isRejected => outcome == 'REJECTED';

  @override
  List<Object?> get props => [studentId, evaluationId, outcome, reason, note];
}

/// Réponse du push d'un lot de notes : la liste d'outcomes par ligne +
/// `serverTime` (horloge serveur indicative du lot — PAS un curseur ; le
/// curseur par note vit dans `NoteSyncViewModel.serverUpdatedAt`, propre à
/// chaque outcome). Parsing **tolérant** : une ligne d'outcome malformée est
/// ignorée (elle restera PENDING → re-poussée).
class NotesBatchResponseModel extends Equatable {
  final List<NoteOutcomeModel> outcomes;
  final String? serverTime;

  const NotesBatchResponseModel({this.outcomes = const [], this.serverTime});

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
      serverTime: json['serverTime'] as String?,
    );
  }

  @override
  List<Object?> get props => [outcomes, serverTime];
}
