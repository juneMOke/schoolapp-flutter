import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';

/// Le geste de décision sur une justification, tel qu'il dort dans l'outbox
/// (`POST /sync/attendance-justifications/{id}/decision`). Idempotent par
/// [gestureId], qui est aussi l'id de l'entrée d'outbox.
class JustificationDecisionPayload extends Equatable {
  final String gestureId;
  final String justificationId;

  /// `ACCEPT` ou `REJECT`.
  final String decision;
  final String? note;

  /// L'utilisateur connecté au moment du geste : le serveur le compare au
  /// jeton (403 sinon).
  final String? authorId;

  const JustificationDecisionPayload({
    required this.gestureId,
    required this.justificationId,
    required this.decision,
    this.note,
    this.authorId,
  });

  /// Le corps envoyé : sans l'id de la justification, qui est dans le chemin.
  Map<String, dynamic> toWireJson() => {
    'gestureId': gestureId,
    'decision': decision,
    'note': ?note,
    kOutboxAuthorIdKey: authorId,
  };

  Map<String, dynamic> toJson() => {
    ...toWireJson(),
    'justificationId': justificationId,
  };

  String toJsonString() => jsonEncode(toJson());

  factory JustificationDecisionPayload.fromJsonString(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return JustificationDecisionPayload(
      gestureId: json['gestureId'] as String,
      justificationId: json['justificationId'] as String,
      decision: json['decision'] as String,
      note: json['note'] as String?,
      authorId: json[kOutboxAuthorIdKey] as String?,
    );
  }

  @override
  List<Object?> get props => [
    gestureId,
    justificationId,
    decision,
    note,
    authorId,
  ];
}
