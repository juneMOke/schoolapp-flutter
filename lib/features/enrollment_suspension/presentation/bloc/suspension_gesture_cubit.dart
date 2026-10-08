import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_state.dart';

/// Pilote une modale de désactivation ou de réactivation.
class SuspensionGestureCubit extends Cubit<SuspensionGestureState> {
  final SuspendStudentsUseCase _suspend;
  final ReactivateStudentsUseCase _reactivate;

  SuspensionGestureCubit({
    required SuspendStudentsUseCase suspend,
    required ReactivateStudentsUseCase reactivate,
  }) : _suspend = suspend,
       _reactivate = reactivate,
       super(const SuspensionGestureIdle());

  Future<void> suspend(
    List<SuspensionTarget> targets, {
    SuspensionReason? reason,
    String? precision,
  }) async {
    if (state is SuspensionGestureBusy) return;
    emit(const SuspensionGestureBusy());
    final result = await _suspend(
      targets,
      reason: reason,
      precision: precision,
    );
    if (isClosed) return;
    emit(result.fold(SuspensionGestureFailed.new, SuspensionGestureDone.new));
  }

  Future<void> reactivate(List<SuspensionTarget> targets) async {
    if (state is SuspensionGestureBusy) return;
    emit(const SuspensionGestureBusy());
    final result = await _reactivate(targets);
    if (isClosed) return;
    emit(result.fold(SuspensionGestureFailed.new, SuspensionGestureDone.new));
  }
}
