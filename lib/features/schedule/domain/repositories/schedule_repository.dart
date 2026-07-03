import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Contrat du module emploi du temps. Tout renvoie `Either<Failure, T>`.
abstract class ScheduleRepository {
  /// Emploi du temps de l'enseignant **connecté** (résolu côté backend via le
  /// JWT). [WeeklyTimetable.teacherId] renseigné, `classroomId` nul.
  Future<Either<Failure, WeeklyTimetable>> getMyTimetable(
    String academicYearId,
  );

  /// Grille d'une classe (surface conseil pédagogique / admin).
  /// [WeeklyTimetable.classroomId] renseigné, `teacherId` nul.
  Future<Either<Failure, WeeklyTimetable>> getClassroomGrid(
    String classroomId,
    String academicYearId,
  );

  /// Crée un créneau de sonnerie (une ligne de la grille).
  Future<Either<Failure, TimeSlot>> createTimeSlot(
    CreateTimeSlotRequest request,
  );

  /// Place un cours à l'emploi du temps et renvoie la séance créée.
  Future<Either<Failure, Session>> createSession(CreateSessionRequest request);

  /// Retire une séance. Renvoie `Right(unit)` sur succès (HTTP 204).
  Future<Either<Failure, Unit>> deleteSession(String sessionId);
}
