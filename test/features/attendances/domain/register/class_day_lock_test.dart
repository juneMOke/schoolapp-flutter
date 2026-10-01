import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_lock.dart';

import '../../presentation/register/class_presence_fixtures.dart';

void main() {
  const today = '2026-10-01';
  const yesterday = '2026-09-30';

  ClassDayLock? lock(
    bool validated, {
    String day = today,
    bool reopened = false,
    bool monthClosed = false,
    bool canWrite = true,
    bool canAmend = false,
    bool justifying = false,
  }) => classDayLock(
    presenceDay(
      day: day,
      validated: validated,
      reopened: reopened,
      monthClosed: monthClosed,
    ),
    today: today,
    canWrite: canWrite,
    canAmend: canAmend,
    justifying: justifying,
  );

  test('sans attendance.write, tout est refusé', () {
    expect(lock(false, canWrite: false), ClassDayLock.forbidden);
  });

  test('un mois clos fige tout, justification comprise', () {
    expect(
      lock(true, monthClosed: true, justifying: true),
      ClassDayLock.monthClosed,
    );
  });

  test('l appel du jour en cours de saisie est libre', () {
    expect(lock(false), isNull);
    expect(lock(false, day: yesterday), isNull);
  });

  test('un appel validé se rouvre ; un jour passé exige amend', () {
    expect(lock(true), ClassDayLock.validated);
    expect(lock(true, day: yesterday), ClassDayLock.needsAmend);
    expect(lock(true, day: yesterday, canAmend: true), ClassDayLock.validated);
  });

  test('justifier un appel validé, même passé, reste permis', () {
    expect(lock(true, day: yesterday, justifying: true), isNull);
  });

  test('un jour passé rouvert ne se corrige pas sans amend', () {
    expect(
      lock(false, day: yesterday, reopened: true),
      ClassDayLock.needsAmend,
    );
    expect(lock(false, day: yesterday, reopened: true, canAmend: true), isNull);
    expect(lock(false, reopened: true), isNull);
  });
}
