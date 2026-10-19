import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';
import 'package:school_app_flutter/features/student/domain/usecases/find_student_identity_use_case.dart';

/// Retrouve, une fois, l'identité d'un élève pour une fiche ouverte par son
/// adresse. Une lecture en échec vaut « inconnu » : la fiche dit alors
/// elle-même qu'elle ne sait pas de qui il s'agit.
class StudentIdentityCubit extends Cubit<StudentIdentityState> {
  final FindStudentIdentityUseCase _find;

  StudentIdentityCubit(this._find) : super(const StudentIdentityState());

  Future<void> resolve({
    required String studentId,
    required String academicYearId,
  }) async {
    final result = await _find(
      studentId: studentId,
      academicYearId: academicYearId,
    );
    if (isClosed) return;
    emit(
      StudentIdentityState(
        resolved: true,
        identity: result.fold((_) => null, (identity) => identity),
      ),
    );
  }
}

class StudentIdentityState extends Equatable {
  final bool resolved;
  final StudentIdentity? identity;

  const StudentIdentityState({this.resolved = false, this.identity});

  @override
  List<Object?> get props => [resolved, identity];
}
