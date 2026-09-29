import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_job_catalog.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_seniority.dart';

import '../staff_builders.dart';

void main() {
  const today = '2026-09-29';
  StaffDraftValidation check(
    StaffMemberDraft draft, {
    List<StaffMember> others = const [],
  }) => StaffDraftValidator.validate(draft, today: today, others: others);

  test('une fiche complète passe', () {
    expect(check(completeDraft()).isValid, isTrue);
  });

  test('une fiche vide : chaque champ requis, rangé à son étape', () {
    final validation = check(const StaffMemberDraft(id: 'x'));

    expect(validation.errors.keys.toSet(), {
      StaffField.lastName,
      StaffField.middleName,
      StaffField.firstName,
      StaffField.sex,
      StaffField.phone,
      StaffField.district,
      StaffField.municipality,
      StaffField.neighborhood,
      StaffField.category,
      StaffField.jobTitle,
      StaffField.entryDate,
    });
    expect(validation.stepsWithErrors, {0, 1, 2});
    expect(validation.firstInvalidStep, 0);
    expect(validation.errorsInStep(1), hasLength(3));
  });

  test('téléphone incomplet, e-mail faux, naissance à venir', () {
    final validation = check(
      completeDraft().copyWith(
        phone: '+24381',
        email: 'pas-une-adresse',
        birthDate: () => '2030-01-01',
      ),
    );

    expect(
      validation.errors[StaffField.phone],
      StaffFieldError.phoneIncomplete,
    );
    expect(validation.errors[StaffField.email], StaffFieldError.emailInvalid);
    expect(
      validation.errors[StaffField.birthDate],
      StaffFieldError.dateInFuture,
    );
  });

  test('un numéro national complet est accepté', () {
    expect(
      check(completeDraft().copyWith(phone: '0824401276')).isValid,
      isTrue,
    );
  });

  test('un diplôme à moitié rempli bloque ; une ligne vide non', () {
    final half = completeDraft().copyWith(
      diplomas: const [StaffDiploma(level: 'L2 — Licence', title: '')],
    );
    final empty = completeDraft().copyWith(
      diplomas: const [StaffDiploma(level: '', title: '')],
    );

    expect(
      check(half).errors[StaffField.diplomas],
      StaffFieldError.diplomaIncomplete,
    );
    expect(check(half).firstInvalidStep, 3);
    expect(check(empty).isValid, isTrue);
  });

  test("l'homonyme avertit sans bloquer, et jamais contre soi-même", () {
    final others = [
      member(
        'm-1',
        lastName: 'KALALA',
        middleName: 'mutombo',
        firstName: 'Didier',
      ),
    ];

    final validation = check(completeDraft(), others: others);
    expect(validation.possibleDuplicate, isTrue);
    expect(validation.isValid, isTrue);

    final self = StaffMemberDraft.of(others.single);
    expect(check(self, others: others).possibleDuplicate, isFalse);
  });

  test('fromSearch range les mots dans l ordre de l état civil', () {
    expect(StaffMemberDraft.fromSearch('id', 'Kiala').lastName, 'Kiala');
    final two = StaffMemberDraft.fromSearch('id', 'Kiala Hervé');
    expect(
      [two.lastName, two.middleName, two.firstName],
      ['Kiala', '', 'Hervé'],
    );
    final four = StaffMemberDraft.fromSearch(
      'id',
      ' Kiala  Mvuemba Hervé Paul ',
    );
    expect(
      [four.lastName, four.middleName, four.firstName],
      ['Kiala', 'Mvuemba', 'Hervé Paul'],
    );
  });

  test('les fonctions suivent la catégorie, la valeur courante gardée', () {
    expect(
      StaffJobCatalog.jobsFor(StaffCategory.support),
      contains('Sentinelle'),
    );
    expect(StaffJobCatalog.jobsFor(null), isEmpty);
    expect(
      StaffJobCatalog.jobsFor(
        StaffCategory.teacher,
        current: 'Inspecteur',
      ).first,
      'Inspecteur',
    );
  });

  test("l'ancienneté se compte en années pleines", () {
    expect(StaffSeniority.yearsAt('2019-09-02', '2026-09-01'), 6);
    expect(StaffSeniority.yearsAt('2019-09-02', '2026-09-02'), 7);
    expect(StaffSeniority.yearsAt('2027-01-01', '2026-09-02'), isNull);
    expect(StaffSeniority.yearsAt(null, '2026-09-02'), isNull);
  });
}
