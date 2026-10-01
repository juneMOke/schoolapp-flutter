import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_commands.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';

/// L'appel d'une classe : lecture locale, filtres en mémoire, gestes au
/// brouillon puis à la file d'envoi.
///
/// La tablette relit le jour affiché à chaque changement (classe, jour,
/// geste) et quand un pull ou un flush le périme.
class ClassPresenceCubit extends Cubit<ClassPresenceState> {
  final LoadClassPresenceDayUseCase _load;
  final ResourceSyncSignals _signals;
  final ClassPresenceCommands commands;
  final DateTime Function() _now;
  void Function()? _unwatch;
  int _seq = 0;

  /// Numéro de la dernière lecture lancée : une lecture plus ancienne qui
  /// répond après ne doit pas écraser la plus récente (double toucher).
  int _read = 0;

  ClassPresenceCubit({
    required LoadClassPresenceDayUseCase load,
    required ResourceSyncSignals signals,
    required this.commands,
    DateTime Function() now = DateTime.now,
  }) : _load = load,
       _signals = signals,
       _now = now,
       super(_initial(now()));

  static ClassPresenceState _initial(DateTime now) {
    final today = SchoolDayCalendar.dayOf(now);
    return ClassPresenceState(
      load: ClassPresenceLoad.noClass,
      today: today,
      // Le week-end, le registre s'ouvre sur le vendredi.
      day: ClassPresenceState.lastSchoolDayOf(today),
    );
  }

  /// L'année de l'appel (et ses bornes), une fois le contexte académique
  /// connu.
  void setAcademicYear(String academicYearId, SchoolYearBounds schoolYear) {
    _unwatch ??= _signals.watch(() => unawaited(refresh()));
    if (academicYearId == state.academicYearId) return;
    emit(
      state.copyWith(academicYearId: academicYearId, schoolYear: schoolYear),
    );
    unawaited(_signals.pull());
  }

  /// Choisit la classe ; le registre revient sans filtre.
  Future<void> selectClassroom(ClassPresenceClassroom classroom) async {
    emit(
      state.copyWith(
        classroom: classroom,
        load: ClassPresenceLoad.loading,
        presenceDay: () => null,
        dayQuery: ClassDayQuery.none,
        clearFailure: true,
      ),
    );
    await _readDay(loading: true);
  }

  /// Relecture **silencieuse** : jamais de squelette, un échec garde l'écran.
  Future<void> refresh() => _readDay(loading: false);

  Future<void> _readDay({required bool loading}) async {
    final classroom = state.classroom;
    final yearId = state.academicYearId;
    if (isClosed || classroom == null || yearId == null) return;
    final ticket = ++_read;
    final result = await _load((
      classroomId: classroom.id,
      academicYearId: yearId,
      day: state.day,
    ));
    if (isClosed || ticket != _read) return;
    result.fold(
      (failure) {
        if (loading || state.presenceDay == null) {
          emit(
            state.copyWith(load: ClassPresenceLoad.failure, failure: failure),
          );
        }
      },
      (day) => emit(
        state.copyWith(
          load: ClassPresenceLoad.ready,
          presenceDay: () => day,
          today: SchoolDayCalendar.dayOf(_now()),
          clearFailure: true,
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  /// Le jour de classe précédent ou suivant ; jamais au-delà d'aujourd'hui.
  Future<void> stepDay(int direction) =>
      _moveDay(SchoolDayCalendar.stepWorkDay(state.day, direction));

  Future<void> goToday() =>
      _moveDay(ClassPresenceState.lastSchoolDayOf(state.today));

  /// Jamais au-delà d'aujourd'hui, ni avant la rentrée : le serveur refuse
  /// un appel hors de l'année scolaire.
  Future<void> _moveDay(String day) async {
    final start = state.schoolYear?.start;
    if (day.compareTo(state.today) > 0 || day == state.day) return;
    if (start != null && day.compareTo(start) < 0) return;
    emit(state.copyWith(day: day));
    await refresh();
  }

  // ── Filtres ───────────────────────────────────────────────────────────

  void setDayStatus(PresenceStatus? status) =>
      emit(state.copyWith(dayQuery: state.dayQuery.withStatus(status)));

  void setDayText(String text) {
    if (text != state.dayQuery.text) {
      emit(state.copyWith(dayQuery: state.dayQuery.withText(text)));
    }
  }

  void resetDayFilters() => emit(state.copyWith(dayQuery: ClassDayQuery.none));

  void setViewMode(CollectionViewMode mode) {
    if (mode != state.viewMode) emit(state.copyWith(viewMode: mode));
  }

  // ── Gestes ────────────────────────────────────────────────────────────

  /// Annonce sans rien écrire (un geste intercepté).
  void announce(ClassPresenceNotice notice) =>
      emit(state.copyWith(notice: notice.withSeq(++_seq)));

  /// Exécute un geste des [commands] sur le jour affiché, relit la tablette
  /// et annonce l'issue.
  Future<void> perform(
    Future<ClassPresenceNotice?> Function(
      ClassPresenceCommands commands,
      ClassPresenceDay day,
    )
    gesture,
  ) async {
    final day = state.presenceDay;
    if (day == null) return;
    final notice = await gesture(commands, day);
    if (isClosed) return;
    await refresh();
    if (isClosed || notice == null) return;
    emit(state.copyWith(notice: notice.withSeq(++_seq)));
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
