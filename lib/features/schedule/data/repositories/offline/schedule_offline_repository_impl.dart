import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/data/sync/time_grids_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/services/teacher_week_rows.dart';

/// Implémentation **offline-first** de [ScheduleRepository].
///
/// - [getMyTimetable] : composé EN LOCAL depuis `ref_time_slots` +
///   `ref_recurring_sessions`, **filtré sur le compte connecté**
///   (`owner_uid`). Le pull est certes cadré enseignant côté serveur (dérivé du
///   token, commit back `1ec6be3` — DF-K), mais la base locale est partagée par
///   tous les comptes de la tablette : sans ce filtre, un prof lirait les
///   séances de son collègue (cf. `core/offline/owner_scope.dart`). Chaque
///   créneau × jour porte au plus une séance (cellule dénormalisée).
/// - [getClassroomGrid] et les écritures (planning admin) : **délégués à
///   l'online** (surface conseil pédagogique / admin, hors périmètre offline).
class ScheduleOfflineRepositoryImpl implements ScheduleRepository {
  final ScheduleRepository _online;
  final ScheduleRefLocalDataSource _refLocal;
  final CurrentUserContext? _currentUser;
  final TimeGridDao? _gridDao;

  const ScheduleOfflineRepositoryImpl({
    required ScheduleRepository online,
    required ScheduleRefLocalDataSource refLocalDataSource,
    CurrentUserContext? currentUser,
    TimeGridDao? gridDao,
  }) : _online = online,
       _refLocal = refLocalDataSource,
       _currentUser = currentUser,
       _gridDao = gridDao;

  @override
  Future<Either<Failure, WeeklyTimetable>> getMyTimetable(
    String academicYearId,
  ) async {
    try {
      final uid = _currentUser?.uid;
      final slots = await _refLocal.getTimeSlots(); // triés par slot_order
      final mine = await _refLocal.getSessionsForYear(
        academicYearId,
        ownerUid: uid,
      );

      // Jours présents dans mes séances, ordonnés selon Weekday.values.
      final present = mine.map((s) => WeekdayX.fromWire(s.dayOfWeek)).toSet();
      final days = Weekday.values
          .where(present.contains)
          .toList(growable: false);

      // Index (créneau, jour) → séance.
      final byCell = <String, RefRecurringSessionRow>{};
      for (final s in mine) {
        byCell['${s.timeSlotId}|${s.dayOfWeek.toUpperCase()}'] = s;
      }

      // Rangées par heure, grilles de l'enseignant seulement (EDT-1).
      final ordered = TeacherWeekRows.compose(
        slots: [
          for (final slot in slots)
            GridTimeSlot(
              TimeSlot(
                id: slot.id,
                order: slot.slotOrder,
                startTime: slot.startTime,
                endTime: slot.endTime,
                label: slot.label,
              ),
              slot.timeGridId,
            ),
        ],
        usedSlotIds: {for (final s in mine) s.timeSlotId},
        grids: await _grids(),
      );
      final rows = [
        for (final slot in ordered)
          TimetableRow(
            timeSlot: slot,
            cells: <Weekday, TimetableCell?>{
              for (final d in days)
                d: slot.isBreak
                    ? null
                    : _cellFrom(byCell['${slot.id}|${d.wire}']),
            },
          ),
      ];

      return Right(
        WeeklyTimetable(
          academicYearId: academicYearId,
          teacherId: uid,
          classroomId: null,
          days: days,
          rows: rows,
        ),
      );
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  Future<Map<String, TimeGrid>> _grids() async {
    final dao = _gridDao;
    return dao == null ? const {} : dao.all();
  }

  TimetableCell? _cellFrom(RefRecurringSessionRow? s) => s == null
      ? null
      : TimetableCell(
          sessionId: s.id,
          coursId: s.coursId,
          classroomId: s.classroomId,
          classroomLabel: s.classroomLabel,
          teacherId: s.teacherId,
          teacherLabel: s.teacherLabel,
          subjectLabel: s.subjectLabel,
          room: s.room,
        );

  // ── Délégations online (grille admin + écritures planning) ──────────────────

  @override
  Future<Either<Failure, WeeklyTimetable>> getClassroomGrid(
    String classroomId,
    String academicYearId,
  ) => _online.getClassroomGrid(classroomId, academicYearId);

  @override
  Future<Either<Failure, TimeSlot>> createTimeSlot(
    CreateTimeSlotRequest request,
  ) => _online.createTimeSlot(request);

  @override
  Future<Either<Failure, Session>> createSession(
    CreateSessionRequest request,
  ) => _online.createSession(request);

  @override
  Future<Either<Failure, Unit>> deleteSession(String sessionId) =>
      _online.deleteSession(sessionId);
}
