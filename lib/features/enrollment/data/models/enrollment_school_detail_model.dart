import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentSchoolDetailModel {
  final String id;
  final EnrollmentStatus status;
  final String academicYearId;
  final String enrollmentCode;
  final String previousSchoolName;
  final String previousAcademicYear;
  final String previousSchoolLevelGroup;
  final String previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final bool formerStudent;
  final String? medicalNotes;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String? transferReason;
  final String? cancellationReason;

  const EnrollmentSchoolDetailModel({
    required this.id,
    required this.status,
    required this.academicYearId,
    required this.enrollmentCode,
    required this.previousSchoolName,
    required this.previousAcademicYear,
    required this.previousSchoolLevelGroup,
    required this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent = false,
    this.medicalNotes,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.transferReason,
    this.cancellationReason,
  });

  factory EnrollmentSchoolDetailModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentSchoolDetailModel(
        id: _readString(json['id']),
        status: EnrollmentStatus.fromString(_readString(json['status'])),
        academicYearId: _readString(json['academicYearId']),
        enrollmentCode: _readString(json['enrollmentCode']),
        previousSchoolName: _readString(json['previousSchoolName']),
        previousAcademicYear: _readString(json['previousAcademicYear']),
        previousSchoolLevelGroup: _readString(json['previousSchoolLevelGroup']),
        previousSchoolLevel: _readString(json['previousSchoolLevel']),
        previousRate: _readNullableDouble(json['previousRate']),
        previousRank: _readNullableInt(json['previousRank']),
        validatedPreviousYear: _readNullableBool(json['validatedPreviousYear']),
        // Le contrat le donne non nul, mais un serveur antérieur au champ ne
        // doit pas faire tomber la lecture du dossier : repli sur `false`,
        // c'est-à-dire « rien de déclaré au guichet ».
        formerStudent: _readNullableBool(json['formerStudent']) ?? false,
        medicalNotes: json['medicalNotes']?.toString(),
        schoolLevelGroupId: _readString(json['schoolLevelGroupId']),
        schoolLevelId: _readString(json['schoolLevelId']),
        transferReason: _readString(json['transferReason']),
        cancellationReason: _readString(json['cancellationReason']),
      );

  static String _readString(dynamic value) => value?.toString() ?? '';

  /// **Jamais de repli sur `0`.** Le serveur rend désormais ce champ nul quand
  /// personne ne l'a renseigné, et zéro pour cent est une note, pas une
  /// absence de note : les confondre remettrait à l'écran la valeur inventée
  /// que le contrat vient de supprimer. Une chaîne illisible vaut « on ne sait
  /// pas », pas « zéro ».
  static double? _readNullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  /// Idem : `null` reste `null`. « Année non validée » est un redoublement,
  /// « année non renseignée » n'est rien du tout — et le calcul de la classe
  /// cible traite les deux différemment.
  static bool? _readNullableBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      // Les deux vocabulaires sont reconnus explicitement, et TOUT le reste
      // vaut `null`. Rabattre l'inconnu sur `false` — ce que faisait le repli
      // précédent — ferait lire un redoublement dans une valeur que personne
      // n'a comprise.
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
      return null;
    }

    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'status': status.name,
    'academicYearId': academicYearId,
    'enrollmentCode': enrollmentCode,
    'previousSchoolName': previousSchoolName,
    'previousAcademicYear': previousAcademicYear,
    'previousSchoolLevelGroup': previousSchoolLevelGroup,
    'previousSchoolLevel': previousSchoolLevel,
    'previousRate': previousRate,
    'previousRank': previousRank,
    'validatedPreviousYear': validatedPreviousYear,
    'formerStudent': formerStudent,
    'medicalNotes': medicalNotes,
    'schoolLevelGroupId': schoolLevelGroupId,
    'schoolLevelId': schoolLevelId,
    'transferReason': transferReason,
    'cancellationReason': cancellationReason,
  };

  EnrollmentSchoolDetail toEntity() => EnrollmentSchoolDetail(
    id: id,
    status: status,
    academicYearId: academicYearId,
    enrollmentCode: enrollmentCode,
    previousSchoolName: previousSchoolName,
    previousAcademicYear: previousAcademicYear,
    previousSchoolLevelGroup: previousSchoolLevelGroup,
    previousSchoolLevel: previousSchoolLevel,
    previousRate: previousRate,
    previousRank: previousRank,
    validatedPreviousYear: validatedPreviousYear,
    formerStudent: formerStudent,
    medicalNotes: medicalNotes,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    transferReason: transferReason,
    cancellationReason: cancellationReason,
  );
}
