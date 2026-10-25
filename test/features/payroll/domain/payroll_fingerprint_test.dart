import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';

void main() {
  group('empreinte des lignes (Q2)', () {
    test(
      'forme canonique, triée, uuid en minuscules — recalculée en Python',
      () async {
        const lines = [
          PayrollLine(
            month: '2026-10',
            staffMemberId: '9A1C2A4E-8B7D-4C61-9E2F-5A0B6C7D8E91',
            currency: 'CDF',
            baseInCents: 185000000,
            grossInCents: 185000000,
            netInCents: 185000000,
          ),
          PayrollLine(
            month: '2026-10',
            staffMemberId: '3f1c2a4e-8b7d-4c61-9e2f-5a0b6c7d8e91',
            currency: 'USD',
            baseInCents: 37500,
            grossInCents: 37500,
            netInCents: 27500,
            advances: [
              PayrollLineAdvance(
                advanceId: 'a-1',
                rank: 1,
                installments: 1,
                dueInCents: 10000,
                takenInCents: 10000,
                carriedInCents: 0,
              ),
            ],
          ),
        ];

        // Forme v2 du serveur — recalculée en Python : deux lignes triées,
        // la seconde '9a1c…|CDF|185000000|0|0|0|0|0|185000000|185000000'.
        final v2 = await PayrollFingerprinter.of(lines);
        expect(
          v2.linesDigest,
          '6130d2862d98e3d4d9568c2c22f55459a1efdc3bc271e723edac9eaaa722f5dc',
        );
        expect(v2.totals.last.deductionInCents, 0);
        expect(v2.totals.last.toPayInCents, 27500);

        // Forme v1 : celle des paies figées avant la v2.
        final fingerprint = await PayrollFingerprinter.of(
          lines,
          formulaVersion: 1,
        );

        expect(
          fingerprint.linesDigest,
          '232553d8bca660401d3ebaf648f2a24c3cc3e275f92617f9668bc093cb1555d4',
        );
        expect(fingerprint.lineCount, 2);
        expect(fingerprint.totals.map((t) => t.currency), ['CDF', 'USD']);
        expect(fingerprint.totals.last.advanceInCents, 10000);
      },
    );

    test('livre vide : empreinte de la chaîne vide', () async {
      final fingerprint = await PayrollFingerprinter.of(const []);

      expect(
        fingerprint.linesDigest,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('deux nets permutés : mêmes totaux, agents différents', () {
      final seen = PayrollFingerprinter.digestLines(const [
        PayrollLine(
          month: 'm',
          staffMemberId: 'a',
          currency: 'USD',
          baseInCents: 1,
          grossInCents: 1,
          netInCents: 1,
        ),
        PayrollLine(
          month: 'm',
          staffMemberId: 'b',
          currency: 'USD',
          baseInCents: 2,
          grossInCents: 2,
          netInCents: 2,
        ),
      ]);
      final server = PayrollFingerprinter.digestLines(const [
        PayrollLine(
          month: 'm',
          staffMemberId: 'a',
          currency: 'USD',
          baseInCents: 2,
          grossInCents: 2,
          netInCents: 2,
        ),
        PayrollLine(
          month: 'm',
          staffMemberId: 'b',
          currency: 'USD',
          baseInCents: 1,
          grossInCents: 1,
          netInCents: 1,
        ),
      ]);

      expect(
        PayrollFingerprinter.totalsOf(seen),
        PayrollFingerprinter.totalsOf(server),
      );
      expect(PayrollFingerprinter.differingMembers(seen, server), {'a', 'b'});
    });
  });

  test('uuid5 de la paie : le vecteur du contrat (Q7)', () {
    expect(
      PayrollIds.payrollId(
        schoolId: '3f1c2a4e-8b7d-4c61-9e2f-5a0b6c7d8e91',
        month: '2026-10',
      ),
      'fc692e71-4f14-575c-a4fc-4fd5a492fff3',
    );
  });

  test('uuid5 de l avance d une dépense : le vecteur du back (T10)', () {
    expect(
      PayrollIds.salaryAdvanceIdOf('7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6'),
      'bd759072-c0ed-506c-a502-d263347edd73',
    );
  });

  test('uuid5 de la priorité d un arriéré (T9), recalculé en Python', () {
    expect(
      PayrollIds.arrearsPriorityId(
        staffMemberId: '00000000-0000-4000-8000-000000000001',
        month: '2026-09',
      ),
      'bb81e2af-70d0-5fb4-b9f7-7514768df586',
    );
  });
}
