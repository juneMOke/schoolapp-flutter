import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';

/// Implémentation **offline-first** de [CourseRepository].
///
/// - [getMyCourses] : composée EN LOCAL depuis l'emploi du temps
///   (`ref_recurring_sessions`) — les cours de l'enseignant connecté (filtrés par
///   `teacher_id == uid`), groupés par classe, la classe résolue via
///   `ref_classrooms` (module Classe).
/// - [getCoursNotationDetail] / [createEvaluation] : **délégués à l'online**
///   pour l'instant (migrés en local aux sous-lots NF-7b (c)/(d)).
///
/// ⚠ Hypothèse `CurrentUserContext.uid == teacher_id` : le seul identifiant local
/// de l'utilisateur est l'`uid` d'auth ; on filtre strictement dessus (jamais les
/// cours d'un autre enseignant, quitte à une liste vide si l'hypothèse est
/// fausse — à VÉRIFIER en revue).
class CourseOfflineRepositoryImpl implements CourseRepository {
  final CourseRepository _online;
  final ScheduleRefLocalDataSource _scheduleRefLocal;
  final ClassroomLocalDataSource _classroomLocal;
  final CurrentUserContext? _currentUser;

  const CourseOfflineRepositoryImpl({
    required CourseRepository online,
    required ScheduleRefLocalDataSource scheduleRefLocalDataSource,
    required ClassroomLocalDataSource classroomLocalDataSource,
    CurrentUserContext? currentUser,
  }) : _online = online,
       _scheduleRefLocal = scheduleRefLocalDataSource,
       _classroomLocal = classroomLocalDataSource,
       _currentUser = currentUser;

  @override
  Future<Either<Failure, List<CourseSummary>>> getMyCourses() async {
    try {
      final uid = _currentUser?.uid;
      final sessions = await _scheduleRefLocal.getAllSessions();
      final mine = uid == null
          ? const <RefRecurringSessionRow>[]
          : sessions.where((s) => s.teacherId == uid);

      // Regroupe par classe → cours distincts (id + libellé matière).
      final byClassroom = <String, Map<String, String>>{};
      final classroomLabel = <String, String>{};
      for (final s in mine) {
        classroomLabel[s.classroomId] = s.classroomLabel;
        (byClassroom[s.classroomId] ??= {})[s.coursId] = s.subjectLabel;
      }

      final summaries = <CourseSummary>[];
      for (final entry in byClassroom.entries) {
        final classroomId = entry.key;
        final courses = entry.value.entries
            .map((c) => CourseRef(id: c.key, label: c.value))
            .toList(growable: false);
        final dto = await _classroomLocal.getClassroomById(classroomId);
        final classroom = dto == null
            ? ClassroomSummary(
                id: classroomId,
                schoolLevelId: '',
                name: classroomLabel[classroomId] ?? '',
                capacity: 0,
                totalCount: 0,
                femaleCount: 0,
                maleCount: 0,
              )
            : ClassroomSummary(
                id: dto.id,
                version: dto.version,
                schoolLevelId: dto.schoolLevelId ?? '',
                name: dto.name,
                capacity: dto.capacity ?? 0,
                totalCount: dto.totalCount,
                femaleCount: dto.femaleCount,
                maleCount: dto.maleCount,
              );
        summaries.add(CourseSummary(classroom: classroom, courses: courses));
      }
      return Right(summaries);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  // ── Délégations online (migrées en local aux sous-lots (c)/(d)) ─────────────

  @override
  Future<Either<Failure, CoursNotationDetail>> getCoursNotationDetail(
    String coursId,
  ) => _online.getCoursNotationDetail(coursId);

  @override
  Future<Either<Failure, Evaluation>> createEvaluation(
    String coursId,
    CreateEvaluationRequest request,
  ) => _online.createEvaluation(coursId, request);
}
