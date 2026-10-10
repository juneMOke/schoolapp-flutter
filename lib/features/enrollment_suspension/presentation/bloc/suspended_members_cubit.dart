import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';

/// Les élèves désactivés d'une année et leur classe d'origine, relus à chaque
/// changement annoncé.
class SuspendedMembersCubit extends Cubit<List<SuspendedMember>> {
  final LoadSuspendedMembersUseCase _load;
  final String academicYearId;
  StreamSubscription<Set<String>>? _changes;

  SuspendedMembersCubit(this._load, {required this.academicYearId})
    : super(const <SuspendedMember>[]) {
    _changes = _load.changes.listen((_) => refresh());
    refresh();
  }

  Future<void> refresh() async {
    final result = await _load(academicYearId);
    if (isClosed) return;
    result.fold((_) {}, emit);
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
