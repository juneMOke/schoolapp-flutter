import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';

/// L'état de désactivation d'une inscription : la période qui le dit (ouverte,
/// ou la dernière fermée), `null` si l'élève n'a jamais été désactivé.
class EnrollmentSuspensionStatusState extends Equatable {
  final StudentSuspension? period;

  const EnrollmentSuspensionStatusState([this.period]);

  bool get isSuspended => period?.isOpen ?? false;

  @override
  List<Object?> get props => [period];
}

/// Suit l'état d'une inscription, et se relit à chaque changement annoncé.
class EnrollmentSuspensionStatusCubit
    extends Cubit<EnrollmentSuspensionStatusState> {
  final LoadEnrollmentSuspensionUseCase _load;
  final String enrollmentId;
  StreamSubscription<Set<String>>? _changes;

  EnrollmentSuspensionStatusCubit(this._load, {required this.enrollmentId})
    : super(const EnrollmentSuspensionStatusState()) {
    _changes = _load.changes.listen((ids) {
      if (ids.isEmpty || ids.contains(enrollmentId)) refresh();
    });
    refresh();
  }

  Future<void> refresh() async {
    final result = await _load(enrollmentId);
    if (isClosed) return;
    // Une lecture ratée garde l'état connu : mieux vaut un bandeau en retard
    // qu'un élève désactivé affiché comme actif.
    result.fold(
      (_) {},
      (period) => emit(EnrollmentSuspensionStatusState(period)),
    );
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
