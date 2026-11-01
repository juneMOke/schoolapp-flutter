import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';

/// Où en est l'enregistrement. Une erreur ne passe que par ici : elle ne détruit
/// jamais la grille.
sealed class CoteSaveStatus extends Equatable {
  const CoteSaveStatus();

  @override
  List<Object?> get props => const [];
}

final class CoteSaveIdle extends CoteSaveStatus {
  const CoteSaveIdle();
}

final class CoteSaving extends CoteSaveStatus {
  const CoteSaving();
}

final class CoteSaved extends CoteSaveStatus {
  final int atMs;

  const CoteSaved(this.atMs);

  @override
  List<Object?> get props => [atMs];
}

final class CoteSaveOffline extends CoteSaveStatus {
  final int pending;

  const CoteSaveOffline(this.pending);

  @override
  List<Object?> get props => [pending];
}

/// [sessionExpired] : les cotes attendent la reconnexion, « Réessayer » n'y
/// changerait rien.
final class CoteSaveFailed extends CoteSaveStatus {
  final bool sessionExpired;

  const CoteSaveFailed({this.sessionExpired = false});

  @override
  List<Object?> get props => [sessionExpired];
}

/// Le réseau de la saisie : chaque cellule est déjà sur l'appareil quand ce
/// cubit entre en jeu. Il regroupe les envois ([AppMotion.autosaveDebounce]) et
/// tient le statut à jour, y compris quand la file se vide sans lui (retour du
/// réseau, battement de synchro).
class CoteSaveCubit extends Cubit<CoteSaveStatus> {
  final CotesRepository _repository;
  final Clock _now;

  /// Un vidage vient de finir. Le scope y branche la relecture des cellules.
  void Function()? onFlushed;

  String? _classroomId;
  Timer? _debounce;
  late final void Function() _unsubscribe;

  CoteSaveCubit(this._repository, {this.onFlushed, Clock now = systemClock})
    : _now = now,
      super(const CoteSaveIdle()) {
    _unsubscribe = _repository.addFlushListener(_handleFlushEnd);
  }

  /// La classe ouverte : son reliquat éventuel repart tout de suite.
  Future<void> attach(String classroomId) async {
    _debounce?.cancel();
    _classroomId = classroomId;
    final pending = await _repository.pendingCount(classroomId);
    if (isClosed || _classroomId != classroomId) return;
    if (pending == 0) {
      emit(const CoteSaveIdle());
      return;
    }
    emit(const CoteSaving());
    await flushNow();
  }

  /// Une cellule vient d'être posée.
  void noteChanged() {
    if (_classroomId == null) return;
    emit(const CoteSaving());
    _debounce?.cancel();
    _debounce = Timer(AppMotion.autosaveDebounce, flushNow);
  }

  /// Sans attendre le silence : changement d'élève, sortie, arrière-plan.
  Future<void> flushNow() async {
    _debounce?.cancel();
    final classroomId = _classroomId;
    if (classroomId == null) return;
    final outcome = await _repository.flush(classroomId);
    if (isClosed || _classroomId != classroomId) return;
    // Une frappe arrivée pendant l'envoi a relancé le délai : l'issue dira.
    if (_debounce?.isActive ?? false) return;
    await _publish(outcome, classroomId);
  }

  Future<void> _publish(CoteFlushOutcome outcome, String classroomId) async {
    switch (outcome) {
      case CoteFlushOutcome.done:
        if (state is! CoteSaveIdle) emit(CoteSaved(_now()));
      case CoteFlushOutcome.offline:
        final pending = await _repository.pendingCount(classroomId);
        if (!isClosed) emit(CoteSaveOffline(pending));
      case CoteFlushOutcome.sessionExpired:
        emit(const CoteSaveFailed(sessionExpired: true));
      case CoteFlushOutcome.stuck:
        emit(const CoteSaveFailed());
      case CoteFlushOutcome.busy:
        break;
    }
  }

  /// « Réessayer » : sans le délai de reprise de la file.
  Future<void> retry() async {
    final classroomId = _classroomId;
    if (classroomId == null) return;
    emit(const CoteSaving());
    await _repository.retry(classroomId);
    await flushNow();
  }

  /// Un vidage vient de finir, quel qu'en soit l'auteur.
  Future<void> _handleFlushEnd() async {
    onFlushed?.call();
    final classroomId = _classroomId;
    if (classroomId == null || (_debounce?.isActive ?? false)) return;
    if (state is CoteSaveIdle || state is CoteSaved) return;
    final pending = await _repository.pendingCount(classroomId);
    if (isClosed || _classroomId != classroomId) return;
    if (pending == 0) emit(CoteSaved(_now()));
  }

  @override
  Future<void> close() async {
    _unsubscribe();
    final pendingWrite = _debounce?.isActive ?? false;
    _debounce?.cancel();
    final classroomId = _classroomId;
    _classroomId = null;
    if (pendingWrite && classroomId != null) {
      unawaited(_repository.flush(classroomId));
    }
    return super.close();
  }
}
