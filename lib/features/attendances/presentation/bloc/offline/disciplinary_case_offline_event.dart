import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

abstract class DisciplinaryCaseOfflineEvent extends Equatable {
  const DisciplinaryCaseOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les cas disciplinaires locaux d'un élève sur une année (DF-2).
class LoadOfflineDisciplinaryCases extends DisciplinaryCaseOfflineEvent {
  final String studentId;
  final String academicYearId;

  const LoadOfflineDisciplinaryCases({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

/// Crée un cas disciplinaire en local-first (DF-1/2, régime A).
///
/// Regroupe l'intégralité du FAIT (snapshot élève, date, titre, contenu,
/// catégorie, gravité) et l'éventuelle sanction initiale.
class CreateOfflineDisciplinaryCase extends DisciplinaryCaseOfflineEvent {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final DateTime disciplinaryCaseDate;
  final String academicYearId;
  final String title;
  final String content;
  final DisciplinaryCategory category;
  final DisciplinarySeverity severity;
  final DisciplinarySanction? sanction;

  const CreateOfflineDisciplinaryCase({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.disciplinaryCaseDate,
    required this.academicYearId,
    required this.title,
    required this.content,
    required this.category,
    required this.severity,
    this.sanction,
  });

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    disciplinaryCaseDate,
    academicYearId,
    title,
    content,
    category,
    severity,
    sanction,
  ];
}

/// Traite un cas local : statut + sanction courante (DF-2, régime C, LWW).
class UpdateOfflineDisciplinaryCase extends DisciplinaryCaseOfflineEvent {
  final String caseId;
  final DisciplinaryStatus status;
  final DisciplinarySanction? sanction;
  final int? expectedVersion;

  const UpdateOfflineDisciplinaryCase({
    required this.caseId,
    required this.status,
    this.sanction,
    this.expectedVersion,
  });

  @override
  List<Object?> get props => [caseId, status, sanction, expectedVersion];
}

/// Charge les commentaires d'un cas (fil du détail, DF-B).
class LoadOfflineDisciplinaryComments extends DisciplinaryCaseOfflineEvent {
  final String caseId;

  const LoadOfflineDisciplinaryComments(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

/// Ajoute un commentaire append-only (DF-B) puis recharge le fil.
class AddOfflineDisciplinaryComment extends DisciplinaryCaseOfflineEvent {
  final String caseId;
  final String content;
  final String? authorName;

  const AddOfflineDisciplinaryComment({
    required this.caseId,
    required this.content,
    this.authorName,
  });

  @override
  List<Object?> get props => [caseId, content, authorName];
}
