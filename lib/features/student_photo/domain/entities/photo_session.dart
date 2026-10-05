import 'package:equatable/equatable.dart';

/// Une classe proposée à la séance photo.
class SessionClass extends Equatable {
  final String id;
  final String name;

  const SessionClass({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Un élève d'une classe, tel que la séance le photographie.
class SessionStudent extends Equatable {
  final String id;
  final String lastName;
  final String? middleName;
  final String firstName;

  const SessionStudent({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName,
  });

  /// « Nom Post-nom » — la ligne de tête.
  String get familyName => [
    lastName,
    middleName,
  ].whereType<String>().where((p) => p.isNotEmpty).join(' ');

  String get fullName =>
      [familyName, firstName].where((p) => p.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id, lastName, middleName, firstName];
}

/// Ce que la séance a fait pour un élève.
enum SessionItemStatus {
  /// Pas encore photographié.
  todo,

  /// Photographié : la photo est sur le poste (et en file d'envoi).
  photographed,

  /// Absent ce jour : reste reprenable.
  absent,

  /// Passé : reste reprenable.
  skipped;

  bool get isResumable =>
      this == SessionItemStatus.absent || this == SessionItemStatus.skipped;
}

/// Un élève de la file, et ce qu'il est devenu.
class SessionItem extends Equatable {
  final SessionStudent student;
  final SessionItemStatus status;

  const SessionItem(this.student, [this.status = SessionItemStatus.todo]);

  SessionItem withStatus(SessionItemStatus status) =>
      SessionItem(student, status);

  @override
  List<Object?> get props => [student, status];
}
