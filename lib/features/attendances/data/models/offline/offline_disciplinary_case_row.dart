import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Ligne sqflite `disciplinary_cases` (DF-1). `content` SENSIBLE (base chiffrée).
class OfflineDisciplinaryCaseRow extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final String academicYearId;

  /// 'yyyy-MM-dd'.
  final String disciplinaryCaseDate;
  final String title;
  final String content;
  final String category;
  final String severity;
  final String status;
  final String? sanction;
  final int? version;
  final int updatedAt;
  final String syncStatus;
  final int? syncedAt;

  const OfflineDisciplinaryCaseRow({
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
    this.category = 'DISRUPTIVE_BEHAVIOR',
    this.severity = 'MINOR',
    this.status = 'OPEN',
    this.sanction,
    this.version,
    required this.updatedAt,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory OfflineDisciplinaryCaseRow.fromMap(Map<String, Object?> map) =>
      OfflineDisciplinaryCaseRow(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        studentFirstName: map['student_first_name'] as String,
        studentLastName: map['student_last_name'] as String,
        studentMiddleName: map['student_middle_name'] as String?,
        studentGender: (map['student_gender'] as String?) ?? 'OTHER',
        academicYearId: map['academic_year_id'] as String,
        disciplinaryCaseDate: map['disciplinary_case_date'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        category: (map['category'] as String?) ?? 'DISRUPTIVE_BEHAVIOR',
        severity: (map['severity'] as String?) ?? 'MINOR',
        status: (map['status'] as String?) ?? 'OPEN',
        sanction: map['sanction'] as String?,
        version: _asIntOrNull(map['version']),
        updatedAt: _asIntOrNull(map['updated_at']) ?? 0,
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncedAt: _asIntOrNull(map['synced_at']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'student_id': studentId,
    'student_first_name': studentFirstName,
    'student_last_name': studentLastName,
    'student_middle_name': studentMiddleName,
    'student_gender': studentGender,
    'academic_year_id': academicYearId,
    'disciplinary_case_date': disciplinaryCaseDate,
    'title': title,
    'content': content,
    'category': category,
    'severity': severity,
    'status': status,
    'sanction': sanction,
    'version': version,
    'updated_at': updatedAt,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
  };

  OfflineDisciplinaryCase toEntity() => OfflineDisciplinaryCase(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: StudentGenderX.fromApiValue(studentGender),
    academicYearId: academicYearId,
    disciplinaryCaseDate: DateOnlyJsonHelper.fromJson(disciplinaryCaseDate),
    title: title,
    content: content,
    category: DisciplinaryCategoryX.fromApiValue(category),
    severity: DisciplinarySeverityX.fromApiValue(severity),
    status: DisciplinaryStatus.fromApiValue(status),
    sanction: sanction == null
        ? null
        : DisciplinarySanctionX.fromApiValue(sanction),
    version: version,
    updatedAt: updatedAt,
    syncState: SyncState.fromDbValue(syncStatus),
    syncedAt: syncedAt,
  );

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
    syncStatus,
    syncedAt,
  ];
}
