import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

export 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_state.dart';

/// La liste de la fiche individuelle (route 4) : un profil par agent sur le
/// mois ou l'année. Changer de portée relit le serveur ; recherche,
/// catégorie et profil se filtrent sur la tablette.
class HrPresenceProfilesCubit extends Cubit<HrPresenceProfilesState> {
  final GetHrAttendanceProfilesUseCase _getProfiles;
  int _ticket = 0;

  HrPresenceProfilesCubit({
    required GetHrAttendanceProfilesUseCase getProfiles,
    DateTime? yearStart,
    DateTime Function() now = DateTime.now,
  }) : _getProfiles = getProfiles,
       super(_initial(yearStart, now()));

  static HrPresenceProfilesState _initial(DateTime? yearStart, DateTime now) {
    final current = SchoolDayCalendar.monthOf(
      // Le mois de l'école, comme le serveur : pas celui de la tablette.
      SchoolDayCalendar.dayOf(SchoolTime.today(now)),
    );
    return HrPresenceProfilesState(
      month: current,
      currentMonth: current,
      firstMonth: yearStart == null
          ? null
          : SchoolDayCalendar.monthOf(SchoolDayCalendar.dayOf(yearStart)),
    );
  }

  Future<void> load() => _read();

  Future<void> setYearly(bool yearly) {
    if (yearly == state.yearly) return Future.value();
    emit(state.copyWith(yearly: yearly));
    return _read();
  }

  Future<void> stepMonth(int direction) {
    if (direction < 0 && !state.canStepBack) return Future.value();
    final month = SchoolDayCalendar.addMonths(state.month, direction);
    if (month.compareTo(state.currentMonth) > 0) return Future.value();
    emit(state.copyWith(month: month));
    return _read();
  }

  Future<void> goCurrentMonth() {
    if (state.isCurrentMonth && !state.yearly) return Future.value();
    emit(state.copyWith(month: state.currentMonth, yearly: false));
    return _read();
  }

  /// La portée lue dans l'adresse ; un mois illisible, à venir ou d'avant la
  /// rentrée vaut le mois en cours.
  Future<void> applyLocation({required bool yearly, String? month}) {
    final asked = _validMonth(month) ?? state.currentMonth;
    if (yearly == state.yearly && asked == state.month) return Future.value();
    emit(state.copyWith(yearly: yearly, month: asked));
    return _read();
  }

  String? _validMonth(String? month) {
    if (month == null || !SchoolDayCalendar.isDay('$month-01')) return null;
    if (month.compareTo(state.currentMonth) > 0) return null;
    final first = state.firstMonth;
    if (first != null && month.compareTo(first) < 0) return null;
    return month;
  }

  void setText(String text) {
    if (text != state.text) emit(state.copyWith(text: text));
  }

  void setCategory(StaffCategory? category) =>
      emit(state.copyWith(category: category));

  /// Un second appui sur la puce active la retire.
  void toggleProfile(PresenceProfile profile) =>
      emit(state.copyWith(profile: state.profile == profile ? null : profile));

  void clearFilters() =>
      emit(state.copyWith(text: '', category: null, profile: null));

  Future<void> retry() => _read();

  Future<void> _read() async {
    final ticket = ++_ticket;
    emit(
      state.copyWith(
        status: HrPresenceProfilesStatus.loading,
        data: null,
        failure: null,
      ),
    );
    final result = await _getProfiles(state.scope);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HrPresenceProfilesStatus.failure,
          failure: failure,
        ),
      ),
      (data) => emit(
        state.copyWith(status: HrPresenceProfilesStatus.ready, data: data),
      ),
    );
  }
}
