import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_state.dart';

/// La liste Communication ▸ Communiqués : chargée en ligne, filtrée sur la
/// tablette. Les critères survivent au passage par l'éditeur ou le détail, et
/// d'une ouverture du menu à l'autre pendant la session ([memory]).
class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  final AnnouncementRepository _repository;
  final OwnerScopedValue<AnnouncementFilters> _memory;
  String? _academicYearId;

  /// L'horloge des dates relatives (« Aujourd'hui », « Demain »).
  final DateTime Function() now;

  AnnouncementsCubit({
    required AnnouncementRepository repository,
    required OwnerScopedValue<AnnouncementFilters> memory,
    this.now = DateTime.now,
  }) : _repository = repository,
       _memory = memory,
       super(AnnouncementsState(filters: memory.value));

  Future<void> load({String? academicYearId}) async {
    _academicYearId = academicYearId ?? _academicYearId;
    emit(state.copyWith(status: AnnouncementsStatus.loading));
    final result = await _repository.list(academicYearId: _academicYearId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AnnouncementsStatus.failure, failure: failure),
      ),
      (items) =>
          emit(state.copyWith(status: AnnouncementsStatus.ready, items: items)),
    );
  }

  /// Un communiqué créé ou modifié ailleurs (éditeur, détail) : remplacé en
  /// place, ou ajouté. Un annulé quitte la liste, qui ne les montre pas.
  void upsert(Announcement announcement) {
    final others = [
      for (final item in state.items)
        if (item.id != announcement.id) item,
    ];
    emit(
      state.copyWith(
        items: announcement.status == AnnouncementStatus.cancelled
            ? others
            : [announcement, ...others],
      ),
    );
  }

  void setQuery(String query) => _filter(state.filters.copyWith(query: query));

  void toggleStatus(AnnouncementStatus status) => _filter(
    state.filters.copyWith(statuses: _toggled(state.filters.statuses, status)),
  );

  void toggleCategory(AnnouncementCategory category) => _filter(
    state.filters.copyWith(
      categories: _toggled(state.filters.categories, category),
    ),
  );

  void clearFilters() => _filter(const AnnouncementFilters());

  void _filter(AnnouncementFilters filters) {
    _memory.value = filters;
    emit(state.copyWith(filters: filters, failure: state.failure));
  }

  static Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}
