import 'package:equatable/equatable.dart';

/// Racine de l'agrégat d'appel poussé au serveur (contrat 1.2.0, `POST
/// /sync/attendance`). `id` = **transport** (la clé d'idempotence réelle est la
/// clé naturelle `(classroomId, attendanceDate, academicYearId)`). `updatedAt`
/// (ISO) = arbitre LWW, rebumpé à chaque modification de l'agrégat. Parsing
/// manuel (payload d'outbox) — pas de build_runner.
class AttendanceSessionInputModel extends Equatable {
  final String id;
  final String classroomId;

  /// 'yyyy-MM-dd'.
  final String attendanceDate;
  final String academicYearId;

  /// Heure métier de l'appel (ISO-8601).
  final String takenAt;
  final String? takenBy;

  /// Arbitre du LWW (ISO-8601, horloge client).
  final String updatedAt;

  const AttendanceSessionInputModel({
    required this.id,
    required this.classroomId,
    required this.attendanceDate,
    required this.academicYearId,
    required this.takenAt,
    this.takenBy,
    required this.updatedAt,
  });

  factory AttendanceSessionInputModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionInputModel(
        id: json['id'] as String,
        classroomId: json['classroomId'] as String,
        attendanceDate: json['attendanceDate'] as String,
        academicYearId: json['academicYearId'] as String,
        takenAt: json['takenAt'] as String,
        takenBy: json['takenBy'] as String?,
        updatedAt: json['updatedAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'classroomId': classroomId,
    'attendanceDate': attendanceDate,
    'academicYearId': academicYearId,
    'takenAt': takenAt,
    'takenBy': takenBy,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    classroomId,
    attendanceDate,
    academicYearId,
    takenAt,
    takenBy,
    updatedAt,
  ];
}
