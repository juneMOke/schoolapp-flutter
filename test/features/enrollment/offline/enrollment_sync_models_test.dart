import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

void main() {
  const tCommand = EnrollmentCommand(
    enrollment: EnrollmentPayload(
      id: 'e1',
      enrollmentType: 'NEW_ENROLLMENT',
      status: 'IN_PROGRESS',
      academicYearId: 'ay-1',
      schoolLevelId: 'lvl-1',
      schoolLevelGroupId: 'grp-1',
      enrollmentDate: '2026-07-06',
      previousRate: 14.5,
      previousRank: 3,
      validatedPreviousYear: true,
    ),
    student: StudentPayload(
      id: 's1',
      firstName: 'Amina',
      lastName: 'Moke',
      surname: 'Junior',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      birthPlace: 'Kinshasa',
      nationality: 'CD',
      city: 'Kinshasa',
    ),
    parents: [
      ParentPayload(
        clientId: 'p1',
        firstName: 'Sarah',
        lastName: 'Moke',
        phoneNumber: '+243111',
        relationshipType: 'MOTHER',
      ),
    ],
  );

  group('payload figé outbox (EnrollmentCommand round-trip)', () {
    test('clés camelCase + dates yyyy-MM-dd', () {
      final json = tCommand.toJson();
      expect(json['enrollment']['enrollmentType'], 'NEW_ENROLLMENT');
      expect(json['enrollment']['enrollmentDate'], '2026-07-06');
      expect(json['student']['dateOfBirth'], '2015-04-02');
      expect(json['parents'][0]['relationshipType'], 'MOTHER');
      expect(json['emitDocument'], true);
    });

    test('round-trip conserve les champs', () {
      final restored = EnrollmentCommand.fromJson(tCommand.toJson());
      expect(restored.enrollment.id, 'e1');
      expect(restored.enrollment.previousRate, 14.5);
      expect(restored.student.gender, 'FEMALE');
      expect(restored.parents.single.phoneNumber, '+243111');
    });
  });

  group('requête réseau (EnrollmentAggregateRequest.toJson — contrat)', () {
    test('dérive studentId + identité snapshottée sur l\'enrollment', () {
      final json = const EnrollmentAggregateRequest(tCommand).toJson();
      final enrollment = json['enrollment'] as Map<String, dynamic>;
      // studentId dérivé du student, identité recopiée sur l'enrollment.
      expect(enrollment['id'], 'e1');
      expect(enrollment['studentId'], 's1');
      expect(enrollment['firstName'], 'Amina');
      expect(enrollment['lastName'], 'Moke');
      expect(enrollment['surname'], 'Junior');
      expect(enrollment['dateOfBirth'], '2015-04-02');
      expect(enrollment['gender'], 'FEMALE');
      expect(enrollment['enrollmentType'], 'NEW_ENROLLMENT');
      // sourceRef null pour NEW (aucune référence d'origine).
      expect(enrollment.containsKey('sourceRef'), isTrue);
      expect(enrollment['sourceRef'], isNull);
    });

    test('sourceRef du payload transporté sur le contrat (RE = matricule)', () {
      const reCommand = EnrollmentCommand(
        enrollment: EnrollmentPayload(
          id: 'e2',
          enrollmentType: 'RE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          academicYearId: 'ay-1',
          enrollmentDate: '2026-07-08',
          sourceRef: 'KIN-2025-0001',
        ),
        student: StudentPayload(
          id: 's1',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          gender: 'FEMALE',
          dateOfBirth: '2015-04-02',
          birthPlace: 'Kinshasa',
          nationality: 'CD',
        ),
        parents: [],
      );

      final json = const EnrollmentAggregateRequest(reCommand).toJson();

      expect(
        (json['enrollment'] as Map<String, dynamic>)['sourceRef'],
        'KIN-2025-0001',
      );
      // Round-trip outbox : le sourceRef survit au gel/relecture du payload.
      final restored = EnrollmentCommand.fromJson(reCommand.toJson());
      expect(restored.enrollment.sourceRef, 'KIN-2025-0001');
    });

    test('student porte le niveau visé ; tuteur par id provisoire', () {
      final json = const EnrollmentAggregateRequest(tCommand).toJson();
      final student = json['student'] as Map<String, dynamic>;
      expect(student['id'], 's1');
      expect(student['schoolLevelId'], 'lvl-1');
      expect(student['schoolLevelGroupId'], 'grp-1');
      // Pas de matricule/email (générés serveur).
      expect(student.containsKey('matriculationNumber'), isFalse);
      expect(student.containsKey('email'), isFalse);

      final parent = (json['parents'] as List).single as Map<String, dynamic>;
      expect(parent['id'], 'p1'); // id provisoire (remappé dans la réponse)
      expect(parent['phoneNumber'], '+243111');
      expect(parent['surname'], 'Moke'); // repli surname → lastName
    });
  });

  group(
    'réponse canonique (EnrollmentAggregateResponse.fromJson — contrat)',
    () {
      test('201/200 : matricule + remap parents + doc + dédup', () {
        final response = EnrollmentAggregateResponse.fromJson({
          'enrollment': {
            'id': 'e1',
            'enrollmentCode': 'ETL-1',
            'status': 'ACTIVE',
          },
          'student': {
            'id': 's1',
            'matriculationNumber': 'MAT-1',
            'email': 'a@b.cd',
          },
          'parents': [
            {
              'providedId': 'p1',
              'canonicalId': 'p-canon',
              'phoneNumber': '+243111',
              'created': false,
            },
          ],
          'documents': [
            {
              'type': 'ENROLLMENT_CERTIFICATE',
              'documentNumber': 'ETL-AI-1',
              'status': 'DEFINITIVE',
              'url': 'https://x/y.pdf',
            },
          ],
          'deduplication': {
            'potentialDuplicate': true,
            'matchedStudentId': 's-other',
            'reason': 'IDENTITY_MATCH',
          },
        });

        expect(response.enrollment.enrollmentCode, 'ETL-1');
        expect(response.student.matriculationNumber, 'MAT-1');
        final remap = response.parents.single;
        expect(remap.providedId, 'p1');
        expect(remap.canonicalId, 'p-canon');
        expect(remap.created, isFalse);
        expect(response.documents.single.documentNumber, 'ETL-AI-1');
        expect(response.deduplication!.potentialDuplicate, isTrue);
        expect(response.deduplication!.matchedStudentId, 's-other');
      });

      test('champs optionnels absents → collections vides / null', () {
        final response = EnrollmentAggregateResponse.fromJson({
          'enrollment': {'id': 'e1', 'status': 'ACTIVE'},
          'student': {'id': 's1'},
        });
        expect(response.parents, isEmpty);
        expect(response.documents, isEmpty);
        expect(response.deduplication, isNull);
        expect(response.student.matriculationNumber, isNull);
        expect(response.enrollment.enrollmentCode, isNull);
      });
    },
  );
}
