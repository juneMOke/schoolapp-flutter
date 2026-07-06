import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_attendance_update_model.dart';

/// Commande d'appel journalier poussée au serveur (AF-2). 1 commande = 1 appel
/// `(classe, date, année)` en mode **full-write** (toutes les lignes du roster :
/// présents ET absents). Sert de payload d'outbox (`toJsonString`/`fromJsonString`).
class OfflineDailyAttendanceCommandModel extends Equatable {
  final String classroomId;

  /// 'yyyy-MM-dd'.
  final String date;
  final String academicYearId;
  final List<OfflineAttendanceUpdateModel> updates;

  const OfflineDailyAttendanceCommandModel({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
    required this.updates,
  });

  factory OfflineDailyAttendanceCommandModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = (json['updates'] as List<dynamic>?) ?? const [];
    return OfflineDailyAttendanceCommandModel(
      classroomId: json['classroomId'] as String,
      date: json['date'] as String,
      academicYearId: json['academicYearId'] as String,
      updates: raw
          .map(
            (e) => OfflineAttendanceUpdateModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'classroomId': classroomId,
    'date': date,
    'academicYearId': academicYearId,
    'updates': updates.map((e) => e.toJson()).toList(),
  };

  /// Sérialisation vers/depuis le champ `payload` (TEXT) de l'outbox.
  String toJsonString() => jsonEncode(toJson());

  factory OfflineDailyAttendanceCommandModel.fromJsonString(String payload) =>
      OfflineDailyAttendanceCommandModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [classroomId, date, academicYearId, updates];
}
