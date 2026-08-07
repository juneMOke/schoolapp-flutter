import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/exigibilite.dart';

void main() {
  final ref = DateTime(2026, 7, 6);

  group('computeExigibilite (règle pure)', () {
    test('A_VENIR si due_at null', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 0,
          dueAt: null,
          reference: ref,
        ),
        ChargeExigibilite.aVenir,
      );
    });

    test('A_VENIR si due_at > reference', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 0,
          dueAt: DateTime(2026, 8, 1),
          reference: ref,
        ),
        ChargeExigibilite.aVenir,
      );
    });

    test('ECHU_SOLDE si échu et reste <= 0', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 1000,
          dueAt: DateTime(2026, 6, 1),
          reference: ref,
        ),
        ChargeExigibilite.echuSolde,
      );
    });

    test('ECHU_SOLDE aussi en cas de trop-perçu (reste négatif)', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 1500,
          dueAt: DateTime(2026, 6, 1),
          reference: ref,
        ),
        ChargeExigibilite.echuSolde,
      );
    });

    test('ECHU_PARTIEL si échu, reste > 0 et paid > 0', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 400,
          dueAt: DateTime(2026, 6, 1),
          reference: ref,
        ),
        ChargeExigibilite.echuPartiel,
      );
    });

    test('ECHU_IMPAYE si échu et rien payé', () {
      expect(
        computeExigibilite(
          expectedInCents: 1000,
          paidInCents: 0,
          dueAt: DateTime(2026, 6, 1),
          reference: ref,
        ),
        ChargeExigibilite.echuImpaye,
      );
    });
  });
}
