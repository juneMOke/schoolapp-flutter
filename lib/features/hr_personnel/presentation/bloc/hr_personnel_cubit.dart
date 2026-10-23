import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

/// Un écran RH · Personnel : lecture **locale** du fichier du personnel — la
/// même que celle du module Ressources humaines, donc la même vérité —, et
/// filtres en mémoire.
///
/// Une instance par écran : le Tableau de bord et le Fichier gardent chacun
/// leur recherche, leur catégorie et leur ordre.
///
/// Au montage, le cubit lit la tablette **puis** tire les flux. Si le fichier
/// n'a jamais été descendu, il attend ce premier tirage avant de conclure : un
/// fichier vide n'est une réponse qu'une fois téléchargé.
class HrPersonnelCubit extends Cubit<HrPersonnelState> {
  final StaffSnapshotSource _source;
  final DateTime Function() _now;
  void Function()? _unwatch;

  HrPersonnelCubit({
    required StaffSnapshotSource source,
    DateTime Function() now = DateTime.now,
  }) : _source = source,
       _now = now,
       super(HrPersonnelState.initial(today: _dayOf(now())));

  Future<void> load() async {
    emit(state.copyWith(status: HrPersonnelStatus.loading, clearFailure: true));
    _unwatch ??= _source.watch(() => unawaited(refresh()));
    final first = await _source.read();
    if (isClosed) return;
    final settled = first.fold(
      (failure) {
        // Une base illisible ne se répare pas en tirant le réseau.
        emit(
          state.copyWith(status: HrPersonnelStatus.failure, failure: failure),
        );
        return true;
      },
      (snapshot) {
        if (!snapshot.hasEverSynced) return false;
        _emitReady(snapshot);
        unawaited(_source.pull());
        return true;
      },
    );
    if (settled) return;

    await _source.pull();
    if (isClosed) return;
    final second = await _source.read();
    if (isClosed) return;
    second.fold(
      (failure) => emit(
        state.copyWith(status: HrPersonnelStatus.failure, failure: failure),
      ),
      _emitReady,
    );
  }

  /// Relecture **silencieuse** après un pull, un flush ou la fermeture d'une
  /// page agent : jamais de squelette, et un échec garde l'écran tel quel.
  Future<void> refresh() async {
    if (isClosed) return;
    final result = await _source.read();
    if (isClosed) return;
    result.fold((_) {}, (snapshot) {
      if (state.status == HrPersonnelStatus.ready) _emitReady(snapshot);
    });
  }

  void _emitReady(StaffFileSnapshot snapshot) => emit(
    state.copyWith(
      status: HrPersonnelStatus.ready,
      snapshot: snapshot,
      today: _dayOf(_now()),
      clearFailure: true,
    ),
  );

  // ── Filtres ───────────────────────────────────────────────────────────

  void setText(String text) {
    if (text == state.query.text) return;
    emit(state.copyWith(query: state.query.withText(text)));
  }

  void setCategory(HrCategoryKey? category) {
    if (category == state.query.category) return;
    emit(state.copyWith(query: state.query.withCategory(category)));
  }

  /// La ligne « Par catégorie » touchée : pose le filtre, ou le retire si
  /// c'était déjà le sien.
  void toggleCategory(HrCategoryKey category) =>
      emit(state.copyWith(query: state.query.toggleCategory(category)));

  void setSort(HrRosterSort sort) {
    if (sort == state.query.sort) return;
    emit(state.copyWith(query: state.query.withSort(sort)));
  }

  /// L'en-tête « Agent » du Fichier : alphabétique, puis inversé.
  void toggleNameOrder() => setSort(
    state.query.sort == HrRosterSort.name
        ? HrRosterSort.nameDescending
        : HrRosterSort.name,
  );

  void clearFilters() => emit(state.copyWith(query: state.query.cleared()));

  void setViewMode(CollectionViewMode mode) {
    if (mode == state.viewMode) return;
    emit(state.copyWith(viewMode: mode));
  }

  static String _dayOf(DateTime moment) {
    final local = moment.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
