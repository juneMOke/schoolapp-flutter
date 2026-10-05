import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';

/// La photo d'une nouvelle inscription, tant que l'élève n'existe pas encore
/// sur le poste.
class StudentPhotoDraftState extends Equatable {
  final Uint8List? photo;
  final DateTime? takenAt;

  /// La fiche de l'élève est écrite : une photo prise désormais part aussitôt.
  final bool studentSaved;

  const StudentPhotoDraftState({
    this.photo,
    this.takenAt,
    this.studentSaved = false,
  });

  @override
  List<Object?> get props => [photo, takenAt, studentSaved];
}

/// Garde la photo d'une nouvelle inscription en mémoire, puis la publie à
/// l'enregistrement de l'étape 1.
///
/// Publiée trop tôt, la photo d'un élève que le serveur ne connaît pas encore
/// — et que le poste n'a même pas écrit — serait refusée comme orpheline.
/// Gardée en mémoire seulement : une inscription abandonnée avant l'étape 1
/// n'a pas d'élève, et sa photo n'a nulle part où aller.
class StudentPhotoDraftCubit extends Cubit<StudentPhotoDraftState> {
  final SaveStudentPhotoUseCase _save;

  StudentPhotoDraftCubit({required SaveStudentPhotoUseCase save})
    : _save = save,
      super(const StudentPhotoDraftState());

  String? _studentId;

  /// Garde [photo] ; part aussitôt si la fiche de l'élève est déjà écrite.
  Future<void> keep(Uint8List photo, DateTime takenAt) async {
    emit(
      StudentPhotoDraftState(
        photo: photo,
        takenAt: takenAt,
        studentSaved: state.studentSaved,
      ),
    );
    final studentId = _studentId;
    if (state.studentSaved && studentId != null) await _publish(studentId);
  }

  /// Retire la photo gardée, avant qu'elle ne parte.
  void discard() =>
      emit(StudentPhotoDraftState(studentSaved: state.studentSaved));

  /// La fiche de [studentId] vient d'être écrite : la photo gardée part.
  Future<void> studentSaved(String studentId) async {
    _studentId = studentId;
    if (!state.studentSaved) {
      emit(
        StudentPhotoDraftState(
          photo: state.photo,
          takenAt: state.takenAt,
          studentSaved: true,
        ),
      );
    }
    await _publish(studentId);
  }

  Future<void> _publish(String studentId) async {
    final photo = state.photo;
    final takenAt = state.takenAt;
    if (photo == null || takenAt == null) return;
    final result = await _save(
      studentId: studentId,
      jpeg: photo,
      takenAt: takenAt,
    );
    if (isClosed) return;
    // Partie : le brouillon s'efface, la photo vit désormais dans la table.
    // Ratée : elle reste gardée, et repartira au prochain enregistrement.
    if (result.isRight() && identical(state.photo, photo)) {
      emit(const StudentPhotoDraftState(studentSaved: true));
    }
  }
}
