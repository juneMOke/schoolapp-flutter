import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';

/// Le nombre d'élèves désactivés d'une année, relu à chaque changement.
class OpenSuspensionsCountCubit extends Cubit<int> {
  final LoadOpenSuspensionsUseCase _load;
  final String academicYearId;
  StreamSubscription<Set<String>>? _changes;

  OpenSuspensionsCountCubit(this._load, {required this.academicYearId})
    : super(0) {
    _changes = _load.changes.listen((_) => refresh());
    refresh();
  }

  Future<void> refresh() async {
    final result = await _load(academicYearId);
    if (isClosed) return;
    result.fold((_) {}, (open) => emit(open.length));
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
