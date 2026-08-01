import 'package:equatable/equatable.dart';

/// Paramètres des pièces scopées « un élève, une année » : note de perception,
/// relevé de compte et quitus financier partagent exactement cette signature
/// côté serveur (`{studentId}` en chemin, `academicYearId` en requête).
class StudentYearDocumentParams extends Equatable {
  final String studentId;
  final String academicYearId;

  const StudentYearDocumentParams({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}
