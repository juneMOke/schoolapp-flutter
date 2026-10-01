import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
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
  final LoadClassPresenceMonthUseCase _loadMonth;
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
    required LoadClassPresenceMonthUseCase loadMonth,
    required ResourceSyncSignals signals,
    required this.commands,
    DateTime Function() now = DateTime.now,
  }) : _load = load,
       _loadMonth = loadMonth,
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
      month: today.substring(0, 7),
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
        monthData: () => null,
        studentId: () => null,
        dayQuery: ClassDayQuery.none,
        recapQuery: ClassRecapQuery.none,
        clearFailure: true,
      ),
    );
    await _readDay(loading: true);
    await _readMonth();
  }

  /// Relecture **silencieuse** : jamais de squelette, un échec garde l'écran.
  Future<void> refresh() async {
    await _readDay(loading: false);
    await _readMonth();
  }

  /// Le mois de la fiche et du récapitulatif — lu seulement quand l'un de
  /// leurs onglets est ouvert. Un échec garde le mois déjà lu.
  Future<void> _readMonth() async {
    final classroom = state.classroom;
    final yearId = state.academicYearId;
    if (isClosed ||
        classroom == null ||
        yearId == null ||
        state.tab == ClassPresenceTab.register) {
      return;
    }
    final month = state.month;
    final result = await _loadMonth((
      classroomId: classroom.id,
      academicYearId: yearId,
      month: month,
    ));
    if (isClosed || month != state.month || classroom != state.classroom) {
      return;
    }
    result.fold((_) {}, (data) => emit(state.copyWith(monthData: () => data)));
  }

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

  void setTab(ClassPresenceTab tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab));
    unawaited(_readMonth());
  }

  /// Le mois précédent ou suivant ; jamais au-delà du mois en cours.
  Future<void> stepMonth(int direction) async {
    if (direction < 0 && !state.canStepMonthBack) return;
    final month = SchoolDayCalendar.addMonths(state.month, direction);
    if (month.compareTo(state.today.substring(0, 7)) > 0) return;
    emit(state.copyWith(month: month, monthData: () => null));
    await _readMonth();
  }

  Future<void> goCurrentMonth() async {
    final month = state.today.substring(0, 7);
    if (month == state.month) return;
    emit(state.copyWith(month: month, monthData: () => null));
    await _readMonth();
  }

  /// Ouvre la fiche mensuelle d'un élève (sélecteur ou récapitulatif).
  void openStudent(String studentId) {
    emit(
      state.copyWith(
        studentId: () => studentId,
        tab: ClassPresenceTab.studentMonth,
      ),
    );
    unawaited(_readMonth());
  }

  void setRecapFilter(ClassRecapFilter filter) =>
      emit(state.copyWith(recapQuery: state.recapQuery.withFilter(filter)));

  void setRecapText(String text) {
    if (text != state.recapQuery.text) {
      emit(state.copyWith(recapQuery: state.recapQuery.withText(text)));
    }
  }

  void resetRecapFilters() =>
      emit(state.copyWith(recapQuery: ClassRecapQuery.none));

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

  /// Clôt le mois affiché, relit et annonce.
  Future<void> closeMonth() async {
    final month = state.monthData;
    final classroom = state.classroom;
    if (month == null || classroom == null) return;
    final notice = await commands.closeMonth(
      month,
      classroomName: classroom.name,
    );
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
