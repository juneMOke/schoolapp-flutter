import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/known_student_identity.dart';

/// Un élève déjà connu **que la sonde a retenu** : son identité, d'où elle
/// vient, et avec quelle force elle ressemble à la saisie du guichet.
///
/// C'est ce que la popin affiche — et rien de plus. Ni tuteur, ni téléphone,
/// ni adresse : un avertissement n'a pas à ouvrir la fiche de quelqu'un.
class EnrollmentDuplicateCandidate extends Equatable {
  final String studentId;

  /// `null` pour un candidat de la cohorte N-1 (cf. [KnownStudentIdentity]).
  final String? enrollmentId;

  final EnrollmentIdentity identity;
  final EnrollmentDuplicateSource source;
  final EnrollmentDuplicateLevel level;

  const EnrollmentDuplicateCandidate({
    required this.studentId,
    required this.identity,
    required this.source,
    required this.level,
    this.enrollmentId,
  });

  factory EnrollmentDuplicateCandidate.from(
    KnownStudentIdentity known,
    EnrollmentDuplicateLevel level,
  ) => EnrollmentDuplicateCandidate(
    studentId: known.studentId,
    enrollmentId: known.enrollmentId,
    identity: known.identity,
    source: known.source,
    level: level,
  );

  @override
  List<Object?> get props => [studentId, enrollmentId, identity, source, level];
}
