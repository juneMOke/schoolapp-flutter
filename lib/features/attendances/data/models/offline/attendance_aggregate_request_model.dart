import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';

/// Agrégat d'appel poussé au serveur (`POST /sync/attendance`, contrat 1.2.0) :
/// `{session, absences[]}` — une classe, un jour, un appel.
///
/// **La liste d'absences est EXHAUSTIVE** (invariant #3) : le serveur réconcilie
/// par différence (ce qui est en base et pas ici est supprimé). Une liste vide
/// est légitime (« appel fait, personne d'absent »). Sert aussi de **payload
/// d'outbox** (`toJsonString`/`fromJsonString`).
class AttendanceAggregateRequestModel extends Equatable {
  final AttendanceSessionInputModel session;
  final List<AttendanceAbsenceInputModel> absences;

  /// Uid de l'auteur (ADR-010 D-05), figé à la saisie. Le serveur (garde A3)
  /// rejette 403 si `authorId ≠ uid` du JWT. `null` = session héritée sans uid.
  final String? authorId;

  const AttendanceAggregateRequestModel({
    required this.session,
    required this.absences,
    this.authorId,
  });

  factory AttendanceAggregateRequestModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['absences'] as List<dynamic>?) ?? const [];
    return AttendanceAggregateRequestModel(
      authorId: json['authorId'] as String?,
      session: AttendanceSessionInputModel.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      absences: raw
          .map(
            (e) =>
                AttendanceAbsenceInputModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
    'session': session.toJson(),
    'absences': absences.map((a) => a.toJson()).toList(),
  };

  /// Sérialisation vers/depuis le champ `payload` (TEXT) de l'outbox.
  String toJsonString() => jsonEncode(toJson());

  factory AttendanceAggregateRequestModel.fromJsonString(String payload) =>
      AttendanceAggregateRequestModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [session, absences, authorId];
}
