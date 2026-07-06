import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Cas disciplinaire lu localement (DF-1). Combine le **FAIT** (immuable :
/// snapshot élève, date, titre, contenu SENSIBLE, catégorie, gravité) et le
/// **TRAITEMENT** (évolutif : statut, sanction, arbitrés par `updatedAt` LWW).
/// `id` = uuid client honoré (idempotence). `disciplinaryCaseDate` conservé
/// localement (le back ne le renvoie pas en lecture).
class OfflineDisciplinaryCase extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final String academicYearId;
  final DateTime disciplinaryCaseDate;
  final String title;
  final String content;
  final DisciplinaryCategory category;
  final DisciplinarySeverity severity;
  final DisciplinaryStatus status;
  final DisciplinarySanction? sanction;
  final int? version;
  final int updatedAt;
  final SyncState syncState;
  final int? syncedAt;

  const OfflineDisciplinaryCase({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.academicYearId,
    required this.disciplinaryCaseDate,
    required this.title,
    required this.content,
    required this.category,
    required this.severity,
    required this.status,
    this.sanction,
    this.version,
    required this.updatedAt,
    this.syncState = SyncState.pendingSync,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    academicYearId,
    disciplinaryCaseDate,
    title,
    content,
    category,
    severity,
    status,
    sanction,
    version,
    updatedAt,
    syncState,
    syncedAt,
  ];
}
