import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';

/// Les enseignants que la direction peut lire, et celui qu'elle lit.
class JournalTeachersState extends Equatable {
  final bool loading;
  final List<JournalTeacher> teachers;
  final String? selectedId;
  final Failure? failure;

  const JournalTeachersState({
    this.loading = true,
    this.teachers = const [],
    this.selectedId,
    this.failure,
  });

  @override
  List<Object?> get props => [loading, teachers, selectedId, failure];
}

class JournalTeachersCubit extends Cubit<JournalTeachersState> {
  final JournalDirectionRepository _direction;

  JournalTeachersCubit(this._direction) : super(const JournalTeachersState());

  Future<void> load() async {
    emit(JournalTeachersState(selectedId: state.selectedId));
    final result = await _direction.teachers();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        JournalTeachersState(
          loading: false,
          selectedId: state.selectedId,
          failure: failure,
        ),
      ),
      (teachers) => emit(
        JournalTeachersState(
          loading: false,
          teachers: teachers,
          selectedId: state.selectedId,
        ),
      ),
    );
  }

  void select(String? teacherId) => emit(
    JournalTeachersState(
      loading: state.loading,
      teachers: state.teachers,
      selectedId: teacherId,
      failure: state.failure,
    ),
  );
}
