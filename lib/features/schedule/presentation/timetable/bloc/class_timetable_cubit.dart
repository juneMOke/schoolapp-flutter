import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'class_timetable_state.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/schedule/data/sync/time_grids_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_timetable_reader.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_pull_handlers.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/copy_source.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/dated_week_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_copy_plan.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Agenda & Horaires ▸ Emploi du temps : la consultation par classe, lue en
/// local (A17 : les versions publiées de toutes les classes descendent sous
/// `schedule.read`).
class ClassTimetableCubit extends Cubit<ClassTimetableState>
    with DatedWeekCubit {
  final ClassTimetableReader _reader;
  @override
  final ClassCalendarReader? calendarReader;
  final TimetableEditor? _editor;
  final PullCoordinator? _coordinator;
  @override
  final DateTime Function() schoolToday;

  ClassTimetableCubit(
    this._reader, {
    this.calendarReader,
    TimetableEditor? editor,
    PullCoordinator? coordinator,
    DateTime Function()? schoolToday,
  }) : _editor = editor,
       _coordinator = coordinator,
       schoolToday = schoolToday ?? DateTime.now,
       super(const ClassTimetableState());

  static const Set<String> resources = {
    kScheduleTimeGridsResource,
    'schedule_time_slots',
    kScheduleProgrammesResource,
    kScheduleTimetablesResource,
    kScheduleTimetableCellsResource,
  };

  Future<void> load({bool pull = false}) async {
    try {
      final coordinator = _coordinator;
      if (pull && coordinator != null) await coordinator.pullSubset(resources);
      final options = await _reader.classOptions();
      if (isClosed) return;
      emit(
        state.copyWith(status: ClassTimetableStatus.ready, options: options),
      );
      await _reloadView();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ClassTimetableStatus.failure,
          failure: StorageFailure(e.toString()),
        ),
      );
    }
  }

  Future<void> selectClass(String? classroomId) async {
    if (classroomId == state.classroomId) return;
    emit(
      state.copyWith(
        classroomId: classroomId,
        clearClassroom: classroomId == null,
        clearView: true,
        clearCalendar: true,
      ),
    );
    await _reloadView();
  }

  void setMode(ClassTimetableMode? mode) => emit(
    mode == null ? state.copyWith(clearMode: true) : state.copyWith(mode: mode),
  );

  void setDay(Weekday? day) => emit(
    day == null ? state.copyWith(clearDay: true) : state.copyWith(day: day),
  );

  // ── Brouillon (sous `schedule.write`) ──

  Future<Either<Failure, Unit>> startDraft() =>
      _edit((editor, view) => editor.start(view));

  Future<Either<Failure, Unit>> setCells(List<CellChange> changes) =>
      _edit((editor, view) => editor.setCells(view, changes));

  /// Les classes de même grille dont on peut copier l'emploi du temps.
  Future<List<CopySource>> copySources() async {
    final view = state.view;
    return view == null ? const [] : _reader.copySources(view);
  }

  /// Copier (I15) : le brouillon est remplacé par la copie, case par case ;
  /// sans brouillon, il commence d'abord.
  Future<Either<Failure, Unit>> copyFrom(CopySource source) async {
    if (!(state.view?.hasDraft ?? false)) {
      final started = await startDraft();
      if (started.isLeft()) return started;
    }
    final view = state.view;
    if (view == null) return const Left(StorageFailure());
    return setCells(TimetableCopyPlan.of(view, source).changes);
  }

  /// « Reprendre ces modifications dans un nouveau brouillon » : un brouillon
  /// commence (ou le brouillon ouvert les reçoit), les gestes refusés y sont
  /// rejoués, puis effacés.
  Future<Either<Failure, Unit>> resumeEnded() async {
    final view = state.view;
    if (view == null || view.ended.isEmpty) return const Right(unit);
    if (!view.hasDraft) {
      final started = await startDraft();
      if (started.isLeft()) return started;
    }
    final current = state.view!;
    final slots = {for (final s in current.slots) s.id: s};
    final courses = {for (final c in current.programme) c.coursId: c};
    final result = await setCells([
      for (final c in view.ended)
        // Un cours sorti du programme ne se rejoue pas en « libérer ».
        if (slots[c.slotId] case final slot?)
          if (c.coursId == null || courses.containsKey(c.coursId))
            CellChange(c.day, slot, courses[c.coursId]),
    ]);
    if (result.isRight()) {
      await _reader.discard(view.ended);
      await _reloadView();
    }
    return result;
  }

  Future<void> discardEnded() async {
    final view = state.view;
    if (view == null) return;
    await _reader.discard(view.ended);
    await _reloadView();
  }

  Future<Either<Failure, Unit>> abandonDraft() =>
      _edit((editor, view) => editor.abandon(view));

  /// En ligne : la révision lue ; ensuite les flux redescendent la version.
  /// « Le brouillon a changé » (TIMETABLE_DRAFT_CHANGED) : l'en-tête est
  /// re-tiré, la prochaine tentative part avec la bonne révision.
  Future<Either<Failure, Unit>> publish() async {
    final result = await _edit((editor, view) => editor.publish(view));
    final coordinator = _coordinator;
    final changed = result.fold(
      (f) =>
          f is TimetableRefusalFailure && f.code == 'TIMETABLE_DRAFT_CHANGED',
      (_) => true,
    );
    if (changed && coordinator != null && !isClosed) {
      try {
        await coordinator.pullSubset(resources);
      } catch (_) {
        // Le tirage suivant rattrapera ; la version locale reste lisible.
      }
      await _reloadView();
    }
    return result;
  }

  Future<Either<Failure, Unit>> _edit(
    Future<Either<Failure, Unit>> Function(TimetableEditor, ClassTimetableView)
    gesture,
  ) async {
    final editor = _editor;
    final view = state.view;
    if (editor == null || view == null || state.busy) {
      return const Left(StorageFailure());
    }
    emit(state.copyWith(busy: true));
    try {
      final result = await gesture(editor, view);
      await _reloadView();
      return result;
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<void> _reloadView() async {
    final selected = state.selected;
    if (selected == null) {
      // Une classe inconnue dans l'adresse (fermée, d'une autre école, lien
      // périmé) : l'adresse se corrige, le sélecteur reste ouvert.
      if (state.classroomId != null &&
          state.status == ClassTimetableStatus.ready &&
          !isClosed) {
        emit(state.copyWith(clearClassroom: true, clearView: true));
      }
      return;
    }
    try {
      final view = await _reader.load(selected);
      if (isClosed || state.classroomId != selected.classroomId) return;
      emit(state.copyWith(view: view));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ClassTimetableStatus.failure,
          failure: StorageFailure(e.toString()),
        ),
      );
      return;
    }
    await reloadCalendar();
  }
}
