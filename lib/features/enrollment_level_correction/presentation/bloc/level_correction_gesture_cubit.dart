import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refused_locally.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';

/// Pourquoi la modale n'a pas pu poser la correction.
enum LevelCorrectionGestureProblem {
  /// Une autre correction de l'inscription attend déjà.
  alreadyPending,

  /// La tablette sait que le serveur refuserait : [LevelCorrectionGestureFailed.refusal].
  refusedLocally,

  /// Écriture locale en échec.
  writeFailed,
}

sealed class LevelCorrectionGestureState extends Equatable {
  const LevelCorrectionGestureState();

  @override
  List<Object?> get props => [];
}

final class LevelCorrectionGestureIdle extends LevelCorrectionGestureState {
  const LevelCorrectionGestureIdle();
}

final class LevelCorrectionGestureBusy extends LevelCorrectionGestureState {
  const LevelCorrectionGestureBusy();
}

final class LevelCorrectionGestureDone extends LevelCorrectionGestureState {
  const LevelCorrectionGestureDone();
}

/// Échec : la saisie est conservée pour un nouvel essai.
final class LevelCorrectionGestureFailed extends LevelCorrectionGestureState {
  final LevelCorrectionGestureProblem problem;
  final LevelCorrectionRefusal? refusal;

  const LevelCorrectionGestureFailed(this.problem, {this.refusal});

  @override
  List<Object?> get props => [problem, refusal];
}

/// Le geste « Corriger le niveau », lancé depuis sa modale.
class LevelCorrectionGestureCubit extends Cubit<LevelCorrectionGestureState> {
  final CorrectLevelUseCase _correct;

  LevelCorrectionGestureCubit(this._correct)
    : super(const LevelCorrectionGestureIdle());

  Future<void> submit(LevelCorrectionRequest request) async {
    if (state is LevelCorrectionGestureBusy) return;
    emit(const LevelCorrectionGestureBusy());
    final result = await _correct(request);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => switch (failure) {
          LevelCorrectionRefusedLocally(:final refusal) =>
            LevelCorrectionGestureFailed(
              LevelCorrectionGestureProblem.refusedLocally,
              refusal: refusal,
            ),
          Failure() => const LevelCorrectionGestureFailed(
            LevelCorrectionGestureProblem.writeFailed,
          ),
        },
        (recorded) => recorded
            ? const LevelCorrectionGestureDone()
            : const LevelCorrectionGestureFailed(
                LevelCorrectionGestureProblem.alreadyPending,
              ),
      ),
    );
  }
}
