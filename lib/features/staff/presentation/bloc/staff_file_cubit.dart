import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

/// La liste du personnel : lecture locale, filtres en mémoire.
///
/// Au montage, le cubit lit la tablette **puis** tire les flux. Si le fichier
/// n'a jamais été descendu, il attend ce premier tirage avant de conclure :
/// un fichier vide n'est une réponse qu'une fois téléchargé.
class StaffFileCubit extends Cubit<StaffFileState> {
  final StaffSnapshotSource _source;
  final DateTime Function() _now;
  void Function()? _unwatch;

  StaffFileCubit({
    required StaffSnapshotSource source,
    DateTime Function() now = DateTime.now,
  }) : _source = source,
       _now = now,
       super(StaffFileState.initial(today: _dayOf(now())));

  Future<void> load() async {
    emit(state.copyWith(status: StaffFileStatus.loading, clearFailure: true));
    _unwatch ??= _source.watch(() => unawaited(refresh()));
    final first = await _source.read();
    if (isClosed) return;
    final settled = first.fold(
      (failure) {
        // Une base illisible ne se répare pas en tirant le réseau.
        emit(state.copyWith(status: StaffFileStatus.failure, failure: failure));
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

    // Jamais descendu : attendre le premier tirage avant de conclure.
    await _source.pull();
    if (isClosed) return;
    final second = await _source.read();
    if (isClosed) return;
    second.fold(
      (failure) => emit(
        state.copyWith(status: StaffFileStatus.failure, failure: failure),
      ),
      (snapshot) => snapshot.hasEverSynced
          ? _emitReady(snapshot)
          : emit(state.copyWith(status: StaffFileStatus.neverSynced)),
    );
  }

  /// Relecture **silencieuse** après un pull ou un flush : jamais de
  /// squelette, et un échec garde l'écran tel quel.
  Future<void> refresh() async {
    if (isClosed) return;
    final result = await _source.read();
    if (isClosed) return;
    result.fold((_) {}, (snapshot) {
      if (snapshot.hasEverSynced || state.status == StaffFileStatus.ready) {
        _emitReady(snapshot);
      }
    });
  }

  void _emitReady(StaffFileSnapshot snapshot) => emit(
    state.copyWith(
      status: StaffFileStatus.ready,
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

  void setCategory(StaffCategory? category) =>
      emit(state.copyWith(query: state.query.withCategory(category)));

  void toggleContract(StaffContractFilter? filter) =>
      emit(state.copyWith(query: state.query.toggleContract(filter)));

  void toggleIncomplete() =>
      emit(state.copyWith(query: state.query.toggleIncomplete()));

  void resetFilters() => emit(state.copyWith(query: StaffFileQuery.none));

  void setViewMode(StaffViewMode mode) {
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
