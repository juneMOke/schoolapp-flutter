import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

part 'session_model.g.dart';

/// Modèle du `SessionDto` : réponse plate de création d'une séance.
///
/// [day] est conservé en `String` wire (`MON`..`SAT`) et converti en [Weekday]
/// dans [toEntity].
@JsonSerializable()
class SessionModel extends Equatable {
  final String id;
  final String academicYearId;
  final String coursId;
  final String timeSlotId;
  final String day;
  final String? room;
  final String teacherId;
  final String classroomId;
  final String teacherLabel;
  final String classroomLabel;
  final String subjectLabel;

  const SessionModel({
    required this.id,
    required this.academicYearId,
    required this.coursId,
    required this.timeSlotId,
    required this.day,
    this.room,
    required this.teacherId,
    required this.classroomId,
    required this.teacherLabel,
    required this.classroomLabel,
    required this.subjectLabel,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);

  Session toEntity() => Session(
    id: id,
    academicYearId: academicYearId,
    coursId: coursId,
    timeSlotId: timeSlotId,
    day: WeekdayX.fromWire(day),
    room: room,
    teacherId: teacherId,
    classroomId: classroomId,
    teacherLabel: teacherLabel,
    classroomLabel: classroomLabel,
    subjectLabel: subjectLabel,
  );

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    coursId,
    timeSlotId,
    day,
    room,
    teacherId,
    classroomId,
    teacherLabel,
    classroomLabel,
    subjectLabel,
  ];
}
