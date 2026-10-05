import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';

/// Le retrait d'une photo, depuis l'étape 1 ou l'en-tête d'une fiche.
class StudentPhotoEditState extends Equatable {
  final bool busy;

  /// Le dernier retrait n'a pas pu être écrit sur le poste.
  final bool failed;

  const StudentPhotoEditState({this.busy = false, this.failed = false});

  @override
  List<Object?> get props => [busy, failed];
}

class StudentPhotoEditCubit extends Cubit<StudentPhotoEditState> {
  final RemoveStudentPhotoUseCase _remove;
  final DateTime Function() _now;

  StudentPhotoEditCubit({
    required RemoveStudentPhotoUseCase remove,
    DateTime Function()? now,
  }) : _remove = remove,
       _now = now ?? DateTime.now,
       super(const StudentPhotoEditState());

  /// Retire la photo ; les initiales reprennent sa place partout, et le
  /// retrait part par l'outbox. Rend `true` s'il est écrit.
  Future<bool> remove(String studentId) async {
    if (state.busy) return false;
    emit(const StudentPhotoEditState(busy: true));
    final result = await _remove(studentId: studentId, removedAt: _now());
    if (isClosed) return false;
    final ok = result.isRight();
    emit(StudentPhotoEditState(failed: !ok));
    return ok;
  }
}
