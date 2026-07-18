import 'package:equatable/equatable.dart';

/// Une exception (absence) de l'agrégat d'appel (contrat 1.2.0). `present`
/// **n'est pas transmis** : une ligne d'absence EST l'exception. Les noms/genre
/// sont **résolus serveur** depuis le roster — le client ne les envoie pas.
/// `id` = transport ; résolution serveur par `(studentId, attendanceDate,
/// academicYearId)`. Parsing manuel (payload d'outbox).
class AttendanceAbsenceInputModel extends Equatable {
  final String id;
  final String studentId;

  /// Motif codé (UPPER_SNAKE) ; `null` = motif non renseigné.
  final String? absenceReason;
  final String? absenceReasonNote;

  /// Arbitre du LWW de la ligne (ISO-8601).
  final String updatedAt;

  const AttendanceAbsenceInputModel({
    required this.id,
    required this.studentId,
    this.absenceReason,
    this.absenceReasonNote,
    required this.updatedAt,
  });

  factory AttendanceAbsenceInputModel.fromJson(Map<String, dynamic> json) =>
      AttendanceAbsenceInputModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        absenceReason: json['absenceReason'] as String?,
        absenceReasonNote: json['absenceReasonNote'] as String?,
        updatedAt: json['updatedAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'absenceReason': absenceReason,
    'absenceReasonNote': absenceReasonNote,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    studentId,
    absenceReason,
    absenceReasonNote,
    updatedAt,
  ];
}
