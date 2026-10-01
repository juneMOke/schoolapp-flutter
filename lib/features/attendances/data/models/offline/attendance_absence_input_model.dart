import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_line_wire.dart';

/// Une exception de l'agrégat d'appel (contrat 1.2.0, v2) : une absence ou
/// un retard. `present` **n'est pas transmis** : une ligne EST l'exception.
/// [status] part toujours (cf. [AttendanceLineWire]) ; l'heure d'arrivée et
/// les minutes ne partent que pour un retard. Les noms/genre
/// sont **résolus serveur** depuis le roster — le client ne les envoie pas.
/// `id` = transport ; résolution serveur par `(studentId, attendanceDate,
/// academicYearId)`. Parsing manuel (payload d'outbox).
class AttendanceAbsenceInputModel extends Equatable {
  final String id;
  final String studentId;

  /// `ABSENT` ou `LATE`.
  final String status;

  /// `HH:mm`, retard seulement.
  final String? arrivalTime;

  /// ≥ 1, retard seulement.
  final int? lateMinutes;

  /// Motif codé (UPPER_SNAKE) ; `null` = motif non renseigné.
  final String? absenceReason;
  final String? absenceReasonNote;

  /// Arbitre du LWW de la ligne (ISO-8601).
  final String updatedAt;

  const AttendanceAbsenceInputModel({
    required this.id,
    required this.studentId,
    this.status = AttendanceLineWire.absent,
    this.arrivalTime,
    this.lateMinutes,
    this.absenceReason,
    this.absenceReasonNote,
    required this.updatedAt,
  });

  factory AttendanceAbsenceInputModel.fromJson(Map<String, dynamic> json) =>
      AttendanceAbsenceInputModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        status: json['status'] as String? ?? AttendanceLineWire.absent,
        arrivalTime: json['arrivalTime'] as String?,
        lateMinutes: (json['lateMinutes'] as num?)?.toInt(),
        absenceReason: json['absenceReason'] as String?,
        absenceReasonNote: json['absenceReasonNote'] as String?,
        updatedAt: json['updatedAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'status': status,
    'arrivalTime': ?arrivalTime,
    'lateMinutes': ?lateMinutes,
    'absenceReason': absenceReason,
    'absenceReasonNote': absenceReasonNote,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    studentId,
    status,
    arrivalTime,
    lateMinutes,
    absenceReason,
    absenceReasonNote,
    updatedAt,
  ];
}
