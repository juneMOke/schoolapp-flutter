import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/disciplinary_case_summary_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

void main() {
  Map<String, dynamic> buildJson() => {
    'id': 'c1',
    'studentId': 's1',
    'studentFirstName': 'John',
    'studentLastName': 'Doe',
    'studentMiddleName': null,
    'studentGender': 'MALE',
    'academicYearId': 'y1',
    'title': 'Fighting in the yard',
    'status': 'OPEN',
    'content': 'The student was involved in a fight.',
    'category': 'FIGHTING',
    'severity': 'SERIOUS',
    'sanction': 'TEMPORARY_EXCLUSION',
    'createdAt': '2026-02-05T08:30:00Z',
  };

  test('fromJson -> toEntity mappe les nouveaux champs + createdAt', () {
    final entity = DisciplinaryCaseSummaryModel.fromJson(
      buildJson(),
    ).toEntity();

    expect(entity.id, 'c1');
    expect(entity.studentGender, StudentGender.male);
    expect(entity.status, DisciplinaryCaseStatus.open);
    expect(entity.category, DisciplinaryCategory.fighting);
    expect(entity.severity, DisciplinarySeverity.serious);
    expect(entity.sanction, DisciplinarySanction.temporaryExclusion);
    expect(entity.createdAt, DateTime.parse('2026-02-05T08:30:00Z'));
  });

  test('valeurs absentes ou inconnues -> unknown (resilience backend)', () {
    final json = buildJson()
      ..remove('category')
      ..remove('severity')
      ..['sanction'] = 'SOMETHING_NEW';

    final entity = DisciplinaryCaseSummaryModel.fromJson(json).toEntity();

    expect(entity.category, DisciplinaryCategory.unknown);
    expect(entity.severity, DisciplinarySeverity.unknown);
    expect(entity.sanction, DisciplinarySanction.unknown);
  });

  test('createdAt absent -> null', () {
    final json = buildJson()..remove('createdAt');

    expect(
      DisciplinaryCaseSummaryModel.fromJson(json).toEntity().createdAt,
      isNull,
    );
  });
}
