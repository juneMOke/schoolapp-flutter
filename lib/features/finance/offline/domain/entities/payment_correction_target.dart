import 'package:equatable/equatable.dart';

/// Un élève vers qui déplacer un versement (D1) : inscrit dans l'année du
/// versement, dans la même école.
class PaymentCorrectionTarget extends Equatable {
  final String studentId;
  final String lastName;
  final String? surname;
  final String firstName;

  /// Le niveau de l'année, pour distinguer deux homonymes.
  final String? levelName;

  const PaymentCorrectionTarget({
    required this.studentId,
    required this.lastName,
    this.surname,
    required this.firstName,
    this.levelName,
  });

  /// Nom · Post-nom · Prénom, l'ordre de toutes les listes d'élèves.
  String get fullName => [
    lastName,
    surname ?? '',
    firstName,
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    studentId,
    lastName,
    surname,
    firstName,
    levelName,
  ];
}
