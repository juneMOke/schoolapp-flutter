import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';

/// Contexte d'ouverture du catalogue de pièces d'un élève.
///
/// Deux identifiants viennent du chemin (résolubles en lien profond), le reste
/// est du **contexte d'affichage** transporté par `extra` : il évite une
/// relecture pour peindre l'en-tête, mais son absence n'empêche jamais
/// d'afficher le catalogue.
///
/// [enrollmentId] mérite une mention à part : c'est la seule clé de
/// l'attestation d'inscription (AI), et elle ne figure pas dans le chemin. Un
/// lien profond ouvre donc un catalogue où l'attestation est indisponible —
/// signalé comme tel, jamais tenté à l'aveugle sur une chaîne vide.
class DocumentsCatalogIntent extends Equatable {
  final String studentId;
  final String academicYearId;
  final String enrollmentId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;

  const DocumentsCatalogIntent({
    required this.studentId,
    required this.academicYearId,
    this.enrollmentId = '',
    this.firstName = '',
    this.lastName = '',
    this.surname = '',
    this.levelName = '',
    this.levelGroupName = '',
  });

  /// Vrai quand l'en-tête peut être peint sans relecture.
  bool get hasDisplayContext =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// Vrai quand l'attestation d'inscription est adressable.
  bool get hasEnrollmentRef => enrollmentId.trim().isNotEmpty;

  DocumentsCatalogIntent withRouteParams({
    required String studentId,
    required String academicYearId,
  }) => DocumentsCatalogIntent(
    studentId: studentId,
    academicYearId: academicYearId,
    enrollmentId: enrollmentId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
  );

  /// L'identité relue en base locale (lien profond, onglet rechargé) :
  /// l'en-tête se peint. La référence de dossier ne s'y lit pas —
  /// l'attestation reste indisponible, signalée comme telle.
  DocumentsCatalogIntent withIdentity(StudentIdentity identity) =>
      DocumentsCatalogIntent(
        studentId: studentId,
        academicYearId: academicYearId,
        enrollmentId: enrollmentId,
        firstName: identity.firstName,
        lastName: identity.lastName,
        surname: identity.surname,
        levelName: identity.levelName,
        levelGroupName: identity.levelGroupName,
      );

  /// Recompose l'intention depuis la route. `extra` est perdu au rechargement
  /// d'un lien profond : on retombe alors sur les deux seuls identifiants du
  /// chemin, sans contexte d'affichage ni référence de dossier.
  static DocumentsCatalogIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is DocumentsCatalogIntent) {
      return extra.withRouteParams(
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }
    return DocumentsCatalogIntent(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    enrollmentId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
  ];
}
