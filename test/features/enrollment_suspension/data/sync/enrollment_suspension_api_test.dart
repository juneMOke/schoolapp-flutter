import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';

import '../../suspension_fixtures.dart';

void main() {
  test('désactiver : le fait sous `suspension`, l\'auteur à côté', () {
    final body = EnrollmentSuspensionApi.bodyOf(
      suspendGesture('s1', reason: SuspensionReason.family, precision: 'p'),
    );
    expect(body['authorId'], kAuthor);
    expect(body['suspension'], {
      'id': 'sus-s1',
      'enrollmentId': 'enr-s1',
      'suspendedAt': '2026-10-08T08:00:00.000Z',
      'suspendedBy': kAuthor,
      'reason': 'FAMILY',
      'precision': 'p',
    });
  });

  test('désactiver sans motif : ni `reason` ni `precision`', () {
    final body = EnrollmentSuspensionApi.bodyOf(suspendGesture('s1'));
    expect(body['suspension'], isNot(contains('reason')));
    expect(body['suspension'], isNot(contains('precision')));
  });

  test('réactiver : le fait sous `reactivation`', () {
    final body = EnrollmentSuspensionApi.bodyOf(reactivateGesture('s1'));
    expect(body['reactivation'], {
      'id': 'rea-s1',
      'enrollmentId': 'enr-s1',
      'reactivatedAt': '2026-10-09T08:00:00.000Z',
      'reactivatedBy': kAuthor,
    });
  });

  test('le geste survit à l\'outbox', () {
    final g = suspendGesture('s1', reason: SuspensionReason.other);
    expect(SuspensionGesture.tryParse(g.toJson()), g);
    expect(SuspensionGesture.tryParse({'op': 'SUSPEND'}), isNull);
  });

  test('accusé : la période sous `period`, absente si jamais suspendu', () {
    final ack = SuspensionGestureAckDto.parse({
      'enrollmentId': 'enr-s1',
      'suspended': true,
      'period': {
        'id': 'p1',
        'enrollmentId': 'enr-s1',
        'studentId': 's1',
        'academicYearId': kYear,
        'suspendedAt': '2026-10-08T08:00:00Z',
        'reason': 'MEDICAL',
      },
    });
    expect(ack.period!.isOpen, isTrue);
    expect(ack.period!.reason, 'MEDICAL');
    expect(
      SuspensionGestureAckDto.parse({
        'enrollmentId': 'enr-s1',
        'suspended': false,
        'period': null,
      }).period,
      isNull,
    );
    expect(
      () => SuspensionGestureAckDto.parse({'suspended': true}),
      throwsFormatException,
    );
  });
}
