import 'package:equatable/equatable.dart';

/// Un élève proposé par la recherche du mode « Élèves » : actif à l'instant,
/// avec sa classe.
class AudienceStudent extends Equatable {
  final String id;
  final String lastName;
  final String? middleName;
  final String? firstName;
  final String? classroomLabel;

  const AudienceStudent({
    required this.id,
    required this.lastName,
    this.middleName,
    this.firstName,
    this.classroomLabel,
  });

  /// « NOM Post-nom Prénom », l'ordre des listes de l'école.
  String get displayName => [
    lastName,
    middleName,
    firstName,
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    id,
    lastName,
    middleName,
    firstName,
    classroomLabel,
  ];
}
