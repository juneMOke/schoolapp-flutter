import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

/// Statut d'un membre de classe (CF1). ACTIVE par défaut ; INACTIVE = sorti /
/// transféré (exclu du roster affiché par défaut).
enum ClassroomMemberStatus {
  active('ACTIVE'),
  inactive('INACTIVE');

  const ClassroomMemberStatus(this.dbValue);

  final String dbValue;

  static ClassroomMemberStatus fromDbValue(String? value) =>
      switch (value?.toUpperCase()) {
        'INACTIVE' => ClassroomMemberStatus.inactive,
        _ => ClassroomMemberStatus.active,
      };
}

/// DTO delta d'un membre de roster (CF2) : transport (pull, `fromJson`) et ligne
/// sqflite (`toMap`/`fromMap`) de `ref_classroom_members`. Snapshot élève
/// dénormalisé (zéro jointure au read). `status`/`version`/`updatedAt` enrichis
/// (CB-1). Parsing manuel — pas de build_runner.
class ClassroomMemberDto extends Equatable {
  final String id;
  final String studentId;
  final String classroomId;
  final String academicYearId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;

  /// Genre wire SCREAMING_SNAKE (MALE|FEMALE|OTHER) — stocké tel quel, réconcilié
  /// en `ClassroomMemberGender` (Classe) ou `StudentGender` (Présence) au read.
  final String studentGender;
  final String status;
  final int? version;
  final int? updatedAt;

  /// Flag COMPOSÉ à la lecture (colonne `has_pending_transfer`, hors miroir) :
  /// l'élève est ici via un transfert local non synchronisé. Jamais persisté.
  final bool hasPendingTransfer;

  const ClassroomMemberDto({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    this.status = 'ACTIVE',
    this.version,
    this.updatedAt,
    this.hasPendingTransfer = false,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory ClassroomMemberDto.fromJson(Map<String, dynamic> json) =>
      ClassroomMemberDto(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        classroomId: json['classroomId'] as String,
        academicYearId: json['academicYearId'] as String,
        studentFirstName: json['studentFirstName'] as String,
        studentLastName: json['studentLastName'] as String,
        studentMiddleName: json['studentMiddleName'] as String?,
        studentGender: (json['studentGender'] as String?) ?? 'OTHER',
        status: (json['status'] as String?) ?? 'ACTIVE',
        version: _asIntOrNull(json['version']),
        updatedAt: _asIntOrNull(json['updatedAt']),
      );

  factory ClassroomMemberDto.fromMap(Map<String, Object?> map) =>
      ClassroomMemberDto(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        classroomId: map['classroom_id'] as String,
        academicYearId: map['academic_year_id'] as String,
        studentFirstName: map['student_first_name'] as String,
        studentLastName: map['student_last_name'] as String,
        studentMiddleName: map['student_middle_name'] as String?,
        studentGender: (map['student_gender'] as String?) ?? 'OTHER',
        status: (map['status'] as String?) ?? 'ACTIVE',
        version: _asIntOrNull(map['version']),
        updatedAt: _asIntOrNull(map['updated_at']),
        hasPendingTransfer:
            (_asIntOrNull(map['has_pending_transfer']) ?? 0) != 0,
      );

  Map<String, Object?> toMap({int? syncedAt}) => <String, Object?>{
    'id': id,
    'student_id': studentId,
    'classroom_id': classroomId,
    'academic_year_id': academicYearId,
    'student_first_name': studentFirstName,
    'student_last_name': studentLastName,
    'student_middle_name': studentMiddleName,
    'student_gender': studentGender,
    'status': status,
    'version': version,
    'updated_at': updatedAt,
    'synced_at': ?syncedAt,
  };

  ClassroomMember toEntity() => ClassroomMember(
    id: id,
    studentId: studentId,
    classroomId: classroomId,
    academicYearId: academicYearId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: ClassroomMemberGender.fromApiValue(studentGender),
    hasPendingTransfer: hasPendingTransfer,
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    classroomId,
    academicYearId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    status,
    version,
    updatedAt,
    hasPendingTransfer,
  ];
}
