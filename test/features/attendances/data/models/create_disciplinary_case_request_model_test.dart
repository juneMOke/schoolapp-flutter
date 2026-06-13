import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/data/models/create_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

void main() {
  test('fromDomain mappe les enums en valeurs API + toJson complet', () {
    final model = CreateDisciplinaryCaseRequestModel.fromDomain(
      studentId: 's1',
      studentFirstName: 'John',
      studentLastName: 'Doe',
      studentMiddleName: 'Junior',
      studentGender: StudentGender.male,
      disciplinaryCaseDate: DateTime(2026, 1, 14),
      academicYearId: 'y1',
      title: 'Altercation',
      content: 'Bagarre dans la cour',
      category: DisciplinaryCategory.fighting,
      severity: DisciplinarySeverity.serious,
      sanction: DisciplinarySanction.temporaryExclusion,
    );

    expect(model.studentGender, 'MALE');
    expect(model.category, 'FIGHTING');
    expect(model.severity, 'SERIOUS');
    expect(model.sanction, 'TEMPORARY_EXCLUSION');

    final json = model.toJson();
    expect(json['category'], 'FIGHTING');
    expect(json['severity'], 'SERIOUS');
    expect(json['sanction'], 'TEMPORARY_EXCLUSION');
    expect(json['studentFirstName'], 'John');
    expect(json['disciplinaryCaseDate'], '2026-01-14');
  });
}
