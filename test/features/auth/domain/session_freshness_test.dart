import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/domain/session_freshness.dart';

void main() {
  const day = Duration(days: 1);
  final base = DateTime(2026, 7, 1).millisecondsSinceEpoch;

  int atDays(int days) => base + day.inMilliseconds * days;

  test('J0–J7 → NORMAL', () {
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: base,
      refreshExpiresAt: atDays(90),
      nowMs: atDays(3),
    );
    expect(eval.mode, SessionMode.normal);
    expect(eval.refreshExpired, isFalse);
  });

  test('J7–J21 → WARNING', () {
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: base,
      refreshExpiresAt: atDays(90),
      nowMs: atDays(10),
    );
    expect(eval.mode, SessionMode.warning);
  });

  test('J21+ → READ_ONLY', () {
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: base,
      refreshExpiresAt: atDays(90),
      nowMs: atDays(25),
    );
    expect(eval.mode, SessionMode.readOnly);
  });

  test('refresh expiré → refreshExpired', () {
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: base,
      refreshExpiresAt: atDays(20),
      nowMs: atDays(25),
    );
    expect(eval.refreshExpired, isTrue);
  });

  test(
    'saut horloge arrière au-delà de la tolérance → clockTampered + READ_ONLY',
    () {
      final eval = SessionFreshness.evaluate(
        lastServerSeenAt: atDays(10),
        refreshExpiresAt: atDays(90),
        nowMs: atDays(
          2,
        ), // device prétend être 8 jours AVANT le dernier contact
      );
      expect(eval.clockTampered, isTrue);
      expect(eval.mode, SessionMode.readOnly);
    },
  );

  test('dérive bénigne dans la tolérance → pas de triche', () {
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: base,
      refreshExpiresAt: atDays(90),
      nowMs: base - 60 * 1000, // 1 min avant : toléré
    );
    expect(eval.clockTampered, isFalse);
    expect(eval.mode, SessionMode.normal);
  });
}
