import 'package:equatable/equatable.dart';

/// Ligne sqflite `ref_recurring_sessions` — remplissage hebdomadaire récurrent
/// de l'emploi du temps. **Référence pure, lecture seule** (peuplée par le pull).
/// Labels **dénormalisés** (`teacherLabel`, `classroomLabel`, `subjectLabel`)
/// pour un affichage sans jointure. `dayOfWeek` = MON…SAT.
class RefRecurringSessionRow extends Equatable {
  final String id;
  final String academicYearId;
  final String coursId;
  final String timeSlotId;
  final String dayOfWeek;
  final String? room;
  final String teacherId;
  final String classroomId;
  final String teacherLabel;
  final String classroomLabel;
  final String subjectLabel;
  final int? serverUpdatedAt;
  final int syncedAt;

  const RefRecurringSessionRow({
    required this.id,
    required this.academicYearId,
    required this.coursId,
    required this.timeSlotId,
    required this.dayOfWeek,
    this.room,
    required this.teacherId,
    required this.classroomId,
    required this.teacherLabel,
    required this.classroomLabel,
    required this.subjectLabel,
    this.serverUpdatedAt,
    required this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory RefRecurringSessionRow.fromMap(Map<String, Object?> map) =>
      RefRecurringSessionRow(
        id: map['id'] as String,
        academicYearId: map['academic_year_id'] as String,
        coursId: map['cours_id'] as String,
        timeSlotId: map['time_slot_id'] as String,
        dayOfWeek: map['day_of_week'] as String,
        room: map['room'] as String?,
        teacherId: map['teacher_id'] as String,
        classroomId: map['classroom_id'] as String,
        teacherLabel: map['teacher_label'] as String,
        classroomLabel: map['classroom_label'] as String,
        subjectLabel: map['subject_label'] as String,
        serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
        syncedAt: _asIntOrNull(map['synced_at']) ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'academic_year_id': academicYearId,
    'cours_id': coursId,
    'time_slot_id': timeSlotId,
    'day_of_week': dayOfWeek,
    'room': room,
    'teacher_id': teacherId,
    'classroom_id': classroomId,
    'teacher_label': teacherLabel,
    'classroom_label': classroomLabel,
    'subject_label': subjectLabel,
    'server_updated_at': serverUpdatedAt,
    'synced_at': syncedAt,
  };

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    coursId,
    timeSlotId,
    dayOfWeek,
    room,
    teacherId,
    classroomId,
    teacherLabel,
    classroomLabel,
    subjectLabel,
    serverUpdatedAt,
    syncedAt,
  ];
}
