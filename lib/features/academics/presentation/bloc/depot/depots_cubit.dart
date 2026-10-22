import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/attachments/attachment_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/depot/depot_copie_use_cases.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_state.dart';

/// Les copies déposées par les parents pour un devoir en ligne : qui a rendu,
/// et l'ouverture de chaque copie.
///
/// Relue à chaque pull des évaluations : un nouveau dépôt fait redescendre
/// le devoir.
class DepotsCubit extends Cubit<DepotsState> {
  final LoadCopiesRenduesUseCase _load;
  final OpenDepotFichierUseCase _open;
  final ResourceSyncSignals _signals;
  final AttachmentAvailabilityTracker _availability;
  void Function()? _unwatch;
  void Function()? _unwatchRadio;
  String? _evaluationId;
  int _read = 0;

  /// Une copie à la fois : un double appui empilerait deux visionneuses.
  bool _opening = false;

  DepotsCubit({
    required LoadCopiesRenduesUseCase load,
    required OpenDepotFichierUseCase open,
    required ResourceSyncSignals signals,
    required AttachmentAvailabilityTracker availability,
  }) : _load = load,
       _open = open,
       _signals = signals,
       _availability = availability,
       super(const DepotsState());

  Future<void> start(String evaluationId) async {
    _evaluationId = evaluationId;
    _unwatch ??= _signals.watch(() => unawaited(refresh()), onFlush: false);
    _unwatchRadio ??= _availability.watch((online) {
      if (!isClosed) {
        emit(state.copyWith(attachments: state.attachments.withOnline(online)));
      }
    });
    unawaited(_signals.pull());
    await refresh();
  }

  Future<void> refresh() async {
    final id = _evaluationId;
    if (id == null) return;
    final read = ++_read;
    final result = await _load(id);
    if (isClosed || read != _read) return;
    final copies = result.fold((failure) {
      // Une relecture qui échoue ne remplace pas une liste déjà montrée.
      if (state.load != DepotsLoad.ready) {
        emit(state.copyWith(load: DepotsLoad.failure, failure: failure));
      }
      return null;
    }, (copies) => copies);
    if (copies == null) return;
    emit(state.copyWith(load: DepotsLoad.ready, copies: copies));
    final attachments = await _availability.snapshot([
      for (final eleve in copies.eleves)
        for (final page in eleve.depot?.fichiers ?? const []) page.ref,
    ]);
    if (isClosed || read != _read) return;
    emit(state.copyWith(attachments: attachments));
  }

  /// Toutes les pages de la copie, dans l'ordre ; la première qui manque
  /// arrête tout (une copie à moitié ouverte tromperait le correcteur).
  Future<Either<Failure, List<AttachmentPart>>> pages(CopieRendue eleve) async {
    final id = _evaluationId;
    final depot = eleve.depot;
    if (id == null || depot == null || !depot.isComplete) {
      return const Left(NotFoundFailure());
    }
    if (_opening) return const Left(ConflictFailure());
    _opening = true;
    try {
      final parts = <AttachmentPart>[];
      for (final page in depot.fichiers) {
        final result = await _open(id, page);
        final Failure? failure = result.fold((failure) => failure, (bytes) {
          parts.add((ref: page.ref, bytes: bytes));
          return null;
        });
        if (failure != null) return Left(failure);
        if (await _availability.isCached(page.ref) && !isClosed) {
          emit(
            state.copyWith(
              attachments: state.attachments.withCached(page.ref.sha256),
            ),
          );
        }
      }
      return Right(parts);
    } finally {
      _opening = false;
    }
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    _unwatchRadio?.call();
    return super.close();
  }
}
