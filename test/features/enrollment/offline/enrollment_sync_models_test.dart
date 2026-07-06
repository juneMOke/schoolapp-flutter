import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

void main() {
  group('requête (toJson/fromJson round-trip)', () {
    final tCommand = const EnrollmentCommand(
      enrollment: EnrollmentPayload(
        id: 'e1',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
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

    test('clés camelCase + dates yyyy-MM-dd', () {
      final json = tCommand.toJson();
      expect(json['enrollment']['enrollmentType'], 'NEW_ENROLLMENT');
      expect(json['enrollment']['enrollmentDate'], '2026-07-06');
      expect(json['student']['dateOfBirth'], '2015-04-02');
      expect(json['parents'][0]['relationshipType'], 'MOTHER');
      expect(json['emitDocument'], true);
    });

    test('EnrollmentCommand round-trip', () {
      final restored = EnrollmentCommand.fromJson(tCommand.toJson());
      expect(restored.enrollment.id, 'e1');
      expect(restored.enrollment.previousRate, 14.5);
      expect(restored.enrollment.previousRank, 3);
      expect(restored.enrollment.validatedPreviousYear, true);
      expect(restored.student.gender, 'FEMALE');
      expect(restored.parents.single.phoneNumber, '+243111');
    });

    test('EnrollmentCommitBatch round-trip', () {
      final batch = EnrollmentCommitBatch([tCommand]);
      final restored = EnrollmentCommitBatch.fromJson(batch.toJson());
      expect(restored.items, hasLength(1));
      expect(restored.items.single.enrollment.id, 'e1');
    });
  });

  group('réponse (ACK fromJson)', () {
    test('COMMITTED avec remap parents + doc', () {
      final result = EnrollmentCommitResult.fromJson({
        'results': [
          {
            'clientEnrollmentId': 'e1',
            'outcome': 'COMMITTED',
            'enrollment': {
              'id': 'e1',
              'status': 'ADMIN_COMPLETED',
              'enrollmentCode': 'ETL-1',
            },
            'student': {
              'id': 's1',
              'matriculationNumber': 'MAT-1',
              'email': 'a@b.cd',
            },
            'parents': [
              {'clientId': 'p1', 'id': 'p-canon', 'phoneNumber': '+243111'},
            ],
            'document': {
              'id': 'd1',
              'type': 'AI',
              'number': 'ETL-AI-1',
              'verificationToken': 'tok',
            },
            'duplicateSignal': {'reason': 'PRE_MATCH'},
          },
        ],
      });

      final ack = result.forClientEnrollmentId('e1')!;
      expect(ack.isCommitted, isTrue);
      expect(ack.student!.matriculationNumber, 'MAT-1');
      expect(ack.parents.single.id, 'p-canon');
      expect(ack.document!.number, 'ETL-AI-1');
      expect(ack.duplicateSignal!.reason, 'PRE_MATCH');
    });

    test('VALIDATION_ERROR expose l\'erreur', () {
      final result = EnrollmentCommitResult.fromJson({
        'results': [
          {
            'clientEnrollmentId': 'e2',
            'outcome': 'VALIDATION_ERROR',
            'error': {'field': 'gender', 'message': 'requis'},
          },
        ],
      });
      final ack = result.forClientEnrollmentId('e2')!;
      expect(ack.isCommitted, isFalse);
      expect(ack.error!.message, 'requis');
    });
  });
}
