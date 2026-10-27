import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';

/// Les bornes du jour affiché, lues dans l'état, telles que les attend la
/// navigation commune des registres (`PresenceDayNavigation`).
mixin ClassPresenceDayView on Cubit<ClassPresenceState> {
  String get shownDay => state.day;

  String? get firstShownDay => state.firstDay;

  String get lastShownDay => ClassPresenceState.lastSchoolDayOf(state.today);
}
