import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';

/// Les filtres de l'appel, en mémoire : ceux du registre du jour et ceux du
/// récapitulatif. Rien n'est relu.
mixin ClassPresenceFilters on Cubit<ClassPresenceState> {
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

  void setRecapFilter(ClassRecapFilter filter) =>
      emit(state.copyWith(recapQuery: state.recapQuery.withFilter(filter)));

  void setRecapText(String text) {
    if (text != state.recapQuery.text) {
      emit(state.copyWith(recapQuery: state.recapQuery.withText(text)));
    }
  }

  void resetRecapFilters() =>
      emit(state.copyWith(recapQuery: ClassRecapQuery.none));
}
