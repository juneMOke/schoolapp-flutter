import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

/// Charge utile passée de la vue classe à la vue focus (patron « en-tête en
/// argument ») : de quoi déclencher le fetch [ResultatFocusRequested] ET rendre
/// immédiatement l'identité de l'élève pendant le chargement, avant que
/// l'`entete` du backend n'arrive.
class ResultatFocusArgs extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final String studentId;

  // Identité affichée dès le chargement (supersédée par l'entete chargée).
  final String nom;
  final String? postnom;
  final String prenom;
  final ClassroomMemberGender? genre;
  final String classroomLabel;

  /// Libellé long de la grande période (« Trimestre 1 ») — l'entité focus ne
  /// porte que l'ordre, pas le découpage : passé ici pour l'en-tête du bulletin.
  final String periodeLabel;

  const ResultatFocusArgs({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.studentId,
    required this.nom,
    this.postnom,
    required this.prenom,
    this.genre,
    required this.classroomLabel,
    required this.periodeLabel,
  });

  @override
  List<Object?> get props => [
    classroomId,
    periodeScolaireId,
    studentId,
    nom,
    postnom,
    prenom,
    genre,
    classroomLabel,
    periodeLabel,
  ];
}
