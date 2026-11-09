import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';

/// La dernière correction de niveau d'une inscription, `null` s'il n'y en a
/// jamais eu sur ce poste.
class LevelCorrectionStatusState extends Equatable {
  final LevelCorrection? correction;

  const LevelCorrectionStatusState([this.correction]);

  /// Une correction attend — en file, ou accusée mais pas encore descendue :
  /// le guichet n'en pose pas une seconde (elle partirait d'un niveau périmé).
  bool get blocksNewCorrection => switch (correction?.status) {
    LevelCorrectionStatus.pending || LevelCorrectionStatus.applied => true,
    _ => false,
  };

  @override
  List<Object?> get props => [correction];
}

/// Suit la correction d'une inscription, et se relit à chaque changement
/// annoncé (geste, accusé, refus, descente).
class LevelCorrectionStatusCubit extends Cubit<LevelCorrectionStatusState> {
  final LoadLevelCorrectionUseCase _load;
  final String enrollmentId;
  StreamSubscription<Set<String>>? _changes;

  LevelCorrectionStatusCubit(
    this._load, {
    required Stream<Set<String>> changes,
    required this.enrollmentId,
  }) : super(const LevelCorrectionStatusState()) {
    _changes = changes.listen((ids) {
      if (ids.isEmpty || ids.contains(enrollmentId)) refresh();
    });
    refresh();
  }

  Future<void> refresh() async {
    final result = await _load(enrollmentId);
    if (isClosed) return;
    // Une lecture ratée garde l'état connu : mieux vaut un bandeau en retard
    // qu'une correction en attente qui disparaît.
    result.fold(
      (_) {},
      (correction) => emit(LevelCorrectionStatusState(correction)),
    );
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
