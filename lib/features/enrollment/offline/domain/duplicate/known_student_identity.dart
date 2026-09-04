import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';

/// Une identité **déjà connue de la tablette**, telle que le corpus local la
/// rend — avant tout rapprochement.
///
/// C'est la matière première de la sonde : le DAO la produit, le usecase la
/// confronte à la saisie. Elle ne porte donc **aucun niveau** : dire à quel
/// point elle ressemble à la saisie n'est pas son travail.
class KnownStudentIdentity extends Equatable {
  final String studentId;

  /// Dossier d'inscription qui porte cette identité. `null` pour la cohorte
  /// N-1 : le dossier de l'an dernier n'est pas dans `enrollments`, seule
  /// l'identité de l'élève y est descendue.
  final String? enrollmentId;

  final EnrollmentIdentity identity;
  final EnrollmentDuplicateSource source;

  const KnownStudentIdentity({
    required this.studentId,
    required this.identity,
    required this.source,
    this.enrollmentId,
  });

  @override
  List<Object?> get props => [studentId, enrollmentId, identity, source];
}
