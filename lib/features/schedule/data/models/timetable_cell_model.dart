import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';

part 'timetable_cell_model.g.dart';

/// Modèle du `TimetableCellDto` : contenu d'une case, libellés déjà résolus.
@JsonSerializable()
class TimetableCellModel extends Equatable {
  final String sessionId;
  final String coursId;
  final String classroomId;
  final String classroomLabel;
  final String teacherId;
  final String teacherLabel;
  final String subjectLabel;
  final String? room;

  const TimetableCellModel({
    required this.sessionId,
    required this.coursId,
    required this.classroomId,
    required this.classroomLabel,
    required this.teacherId,
    required this.teacherLabel,
    required this.subjectLabel,
    this.room,
  });

  factory TimetableCellModel.fromJson(Map<String, dynamic> json) =>
      _$TimetableCellModelFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableCellModelToJson(this);

  TimetableCell toEntity() => TimetableCell(
    sessionId: sessionId,
    coursId: coursId,
    classroomId: classroomId,
    classroomLabel: classroomLabel,
    teacherId: teacherId,
    teacherLabel: teacherLabel,
    subjectLabel: subjectLabel,
    room: room,
  );

  @override
  List<Object?> get props => [
    sessionId,
    coursId,
    classroomId,
    classroomLabel,
    teacherId,
    teacherLabel,
    subjectLabel,
    room,
  ];
}
