import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/navigation/student_record_intent.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';

class FacturationDetailIntent extends Equatable implements StudentRecordIntent {
  @override
  final String studentId;
  @override
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;

  const FacturationDetailIntent({
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
  });

  const FacturationDetailIntent.invalid({
    required String studentId,
    required String academicYearId,
  }) : this(
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
       );

  /// Sait-on **de qui** est cet argent ?
  ///
  /// Le nom, et rien d'autre. C'est la seule chose dont dépende l'ouverture
  /// d'une fiche : le grand-livre se lit avec `studentId` + `academicYearId`,
  /// et ce que la page doit garantir est qu'un solde ne s'affiche jamais sous
  /// une identité inconnue.
  ///
  /// ⚠️ **La classe n'en fait délibérément pas partie**, alors qu'elle y était.
  /// Une recherche **par identité** n'exige aucun niveau (le formulaire bi-mode
  /// arme sur « un nom **ou** un niveau »), le résumé d'élève n'en
  /// porte pas, et le seul niveau disponible est celui des derniers critères —
  /// vide dans ce mode. La fiche ouverte depuis un résultat de recherche par
  /// nom échouait donc cette condition et rendait une carte « contexte
  /// indisponible » à la place du grand-livre : plus aucun frais, plus aucun
  /// versement, pour un élève parfaitement identifié.
  ///
  /// Les deux modules voisins avaient déjà tranché dans l'autre sens, et c'est
  /// leur règle qu'on rejoint : `DisciplinaryStudentDetailIntent` porte lui
  /// aussi niveau, cycle et classe, et n'exige que les noms ; le catalogue
  /// Documents dit la chose en toutes lettres — la classe est « du contexte
  /// d'affichage, jamais une condition d'ouverture ». Ici elle n'alimente que
  /// le sur-titre « Facturation · {classe} », qui retombe déjà sur « - ».
  bool get hasStudentIdentity =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// La fiche rouverte par son adresse : l'identité relue en base locale
  /// remplace celle que la navigation n'a pas pu passer.
  FacturationDetailIntent withIdentity(StudentIdentity identity) =>
      FacturationDetailIntent(
        studentId: studentId,
        academicYearId: academicYearId,
        firstName: identity.firstName,
        lastName: identity.lastName,
        surname: identity.surname,
        levelName: identity.levelName,
        levelGroupName: identity.levelGroupName,
      );

  static FacturationDetailIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) =>
      extraForRecord<FacturationDetailIntent>(
        extra,
        studentId: studentId,
        academicYearId: academicYearId,
      ) ??
      FacturationDetailIntent.invalid(
        studentId: studentId,
        academicYearId: academicYearId,
      );

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
  ];
}
