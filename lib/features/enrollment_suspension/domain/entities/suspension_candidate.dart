import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';

/// Un élève tel que les écrans de désactivation le montrent : la cible du
/// geste, et ce qu'il faut pour le reconnaître (nom, classe).
class SuspensionCandidate extends Equatable {
  final SuspensionTarget target;
  final String lastName;
  final String? middleName;
  final String firstName;
  final String? classLabel;

  const SuspensionCandidate({
    required this.target,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.classLabel,
  });

  String get studentId => target.studentId;

  /// « Nom Post-nom », la ligne forte de l'identité.
  String get familyName => [
    lastName,
    if (middleName != null && middleName!.trim().isNotEmpty) middleName!,
  ].join(' ');

  @override
  List<Object?> get props => [
    target,
    lastName,
    middleName,
    firstName,
    classLabel,
  ];
}
