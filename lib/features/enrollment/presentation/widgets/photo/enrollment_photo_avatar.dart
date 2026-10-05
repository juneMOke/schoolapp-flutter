import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_avatar_button.dart';

/// L'avatar modifiable de l'en-tête du parcours, pour un dossier dont
/// l'élève existe (consultation, validation, réinscription). `null` tant que
/// l'élève n'a ni nom ni identifiant.
Widget? enrollmentPhotoAvatar(EnrollmentDetail? detail) {
  final student = detail?.studentDetail;
  if (student == null || student.id.trim().isEmpty) return null;
  final name = [
    student.lastName,
    student.firstName,
  ].where((part) => part.trim().isNotEmpty).join(' ');
  if (name.isEmpty) return null;
  return PhotoAvatarButton(
    studentId: student.id,
    firstName: student.firstName,
    lastName: student.lastName,
    studentName: name,
  );
}
