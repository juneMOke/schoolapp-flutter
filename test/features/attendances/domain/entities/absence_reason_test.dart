import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

void main() {
  test('isUnjustified : vrai pour unjustified et unknown, faux sinon', () {
    expect(AbsenceReason.unjustified.isUnjustified, isTrue);
    expect(AbsenceReason.unknown.isUnjustified, isTrue);

    final justified = AbsenceReason.values.where(
      (r) => r != AbsenceReason.unjustified && r != AbsenceReason.unknown,
    );
    for (final reason in justified) {
      expect(
        reason.isUnjustified,
        isFalse,
        reason: '$reason ne doit pas etre injustifie',
      );
    }
  });
}
