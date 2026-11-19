import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/schedule/data/sync/time_grids_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_timetable_reader.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_pull_handlers.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

enum ClassTimetableStatus { loading, ready, failure }

/// Semaine ou Jour (EDT-R12) ; `null` : la vue par défaut selon la largeur.
enum ClassTimetableMode { week, day }

class ClassTimetableState extends Equatable {
  final ClassTimetableStatus status;
  final Failure? failure;
  final List<TimetableClassOption> options;
  final String? classroomId;
  final ClassTimetableView? view;
  final ClassTimetableMode? mode;
  final Weekday? day;

  const ClassTimetableState({
    this.status = ClassTimetableStatus.loading,
    this.failure,
    this.options = const [],
    this.classroomId,
    this.view,
    this.mode,
    this.day,
  });

  TimetableClassOption? get selected {
    for (final o in options) {
      if (o.classroomId == classroomId) return o;
    }
    return null;
  }

  ClassTimetableState copyWith({
    ClassTimetableStatus? status,
    Failure? failure,
    List<TimetableClassOption>? options,
    String? classroomId,
    ClassTimetableView? view,
    bool clearView = false,
    ClassTimetableMode? mode,
    bool clearMode = false,
    Weekday? day,
    bool clearDay = false,
  }) => ClassTimetableState(
    status: status ?? this.status,
    failure: failure,
    options: options ?? this.options,
    classroomId: classroomId ?? this.classroomId,
    view: clearView ? null : (view ?? this.view),
    mode: clearMode ? null : (mode ?? this.mode),
    day: clearDay ? null : (day ?? this.day),
  );

  @override
  List<Object?> get props => [
    status,
    failure,
    options,
    classroomId,
    view,
    mode,
    day,
  ];
}

/// Agenda & Horaires ▸ Emploi du temps : la consultation par classe, lue en
/// local (A17 : les versions publiées de toutes les classes descendent sous
/// `schedule.read`).
class ClassTimetableCubit extends Cubit<ClassTimetableState> {
  final ClassTimetableReader _reader;
  final PullCoordinator? _coordinator;

  ClassTimetableCubit(this._reader, {PullCoordinator? coordinator})
    : _coordinator = coordinator,
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
      classroomId == null
          ? ClassTimetableState(
              status: state.status,
              options: state.options,
              mode: state.mode,
              day: state.day,
            )
          : state.copyWith(classroomId: classroomId, clearView: true),
    );
    await _reloadView();
  }

  void setMode(ClassTimetableMode? mode) => emit(
    mode == null ? state.copyWith(clearMode: true) : state.copyWith(mode: mode),
  );

  void setDay(Weekday? day) => emit(
    day == null ? state.copyWith(clearDay: true) : state.copyWith(day: day),
  );

  Future<void> _reloadView() async {
    final selected = state.selected;
    if (selected == null) return;
    final view = await _reader.load(selected);
    if (isClosed || state.classroomId != selected.classroomId) return;
    emit(state.copyWith(view: view));
  }
}
