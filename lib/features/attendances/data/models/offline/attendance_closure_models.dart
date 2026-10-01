import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';

/// Le geste de clôture d'un mois pour une classe
/// (`POST /sync/attendance-closures`). Idempotent par [gestureId], qui est
/// aussi l'id de l'entrée d'outbox.
class AttendanceClosureRequestModel extends Equatable {
  final String gestureId;
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM`.
  final String month;

  /// ISO-8601, l'horloge de la tablette au moment du geste.
  final String clientRecordedAt;
  final String? authorId;

  const AttendanceClosureRequestModel({
    required this.gestureId,
    required this.classroomId,
    required this.academicYearId,
    required this.month,
    required this.clientRecordedAt,
    this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'gestureId': gestureId,
    'classroomId': classroomId,
    'academicYearId': academicYearId,
    'month': month,
    'clientRecordedAt': clientRecordedAt,
    'authorId': authorId,
  };

  factory AttendanceClosureRequestModel.fromJson(Map<String, dynamic> json) =>
      AttendanceClosureRequestModel(
        gestureId: json['gestureId'] as String,
        classroomId: json['classroomId'] as String,
        academicYearId: json['academicYearId'] as String,
        month: json['month'] as String,
        clientRecordedAt: json['clientRecordedAt'] as String,
        authorId: json['authorId'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AttendanceClosureRequestModel.fromJsonString(String payload) =>
      AttendanceClosureRequestModel.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );

  @override
  List<Object?> get props => [
    gestureId,
    classroomId,
    academicYearId,
    month,
    clientRecordedAt,
    authorId,
  ];
}

/// Une clôture telle que le serveur la tient : réponse du POST et ligne du
/// pull.
class AttendanceClosureDto extends Equatable {
  final String? id;
  final String? gestureId;
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM` (le serveur peut renvoyer le 1er du mois : on n'en garde que
  /// l'année et le mois).
  final String month;
  final String? closedAt;
  final String? closedBy;
  final String? serverUpdatedAt;

  const AttendanceClosureDto({
    required this.classroomId,
    required this.academicYearId,
    required this.month,
    this.id,
    this.gestureId,
    this.closedAt,
    this.closedBy,
    this.serverUpdatedAt,
  });

  factory AttendanceClosureDto.fromJson(Map<String, dynamic> json) =>
      AttendanceClosureDto(
        id: json['id'] as String?,
        gestureId: json['gestureId'] as String?,
        classroomId: json['classroomId'] as String,
        academicYearId: json['academicYearId'] as String,
        month: (json['month'] as String).substring(0, 7),
        closedAt: json['closedAt'] as String?,
        closedBy: json['closedBy'] as String?,
        serverUpdatedAt: json['serverUpdatedAt'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    gestureId,
    classroomId,
    academicYearId,
    month,
    closedAt,
    closedBy,
    serverUpdatedAt,
  ];
}

/// Une page keyset de clôtures (`GET /sync/attendance-closures`).
class AttendanceClosurePageDto implements KeysetPageDto<AttendanceClosureDto> {
  @override
  final List<AttendanceClosureDto> items;
  @override
  final KeysetPageEnvelope page;

  const AttendanceClosurePageDto({required this.items, required this.page});

  factory AttendanceClosurePageDto.fromJson(Map<String, dynamic> json) {
    final items = <AttendanceClosureDto>[];
    for (final raw in (json['items'] as List<dynamic>? ?? const [])) {
      try {
        items.add(AttendanceClosureDto.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        // Une ligne illisible n'empêche pas la page : elle reviendra.
      }
    }
    return AttendanceClosurePageDto(
      items: items,
      page: KeysetPageEnvelope.fromJson(json),
    );
  }
}
