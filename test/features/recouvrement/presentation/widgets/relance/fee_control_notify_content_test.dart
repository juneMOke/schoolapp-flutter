import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/export/fee_control_notify_pdf.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FeeControlRow _row(String id, String lastName) => FeeControlRow(
  summary: EnrollmentSummary(
    enrollmentId: 'enr-$id',
    enrollmentCode: 'EL-$id',
    status: 'COMPLETED',
    syncState: SyncState.synced,
    student: StudentSummary(
      id: id,
      firstName: 'Prénom$id',
      lastName: lastName,
      surname: 'Post$id',
      dateOfBirth: '2010-01-01',
      gender: Gender.male,
    ),
  ),
  line: LocalRecoveryLine(
    schoolLevelId: 'lvl-1',
    studentId: id,
    charges: const [
      RecoveryChargePosition(
        feeCode: 'TUITION',
        position: FeeChargePosition(
          currency: 'USD',
          expectedInCents: 22000,
          paidMirrorInCents: 0,
          paidPendingInCents: 0,
        ),
      ),
    ],
  ),
);

const _payerNoPhone = LocalPayerIdentity(
  lastName: 'MOKE',
  firstName: 'Albert',
  origin: PayerOrigin.previousPayment,
);
const _guardianWithPhone = LocalPayerIdentity(
  lastName: 'MOKE',
  firstName: 'Rose',
  phoneNumber: '+243810000001',
  origin: PayerOrigin.guardian,
);

void main() {
  group('resolveNotifyRecipients', () {
    test(
      'un parent joignable prime ; sans aucun : listé sans téléphone',
      () async {
        final recipients = await resolveNotifyRecipients(
          [_row('s1', 'MOKE'), _row('s2', 'ILUNGA'), _row('s3', 'KABONGO')],
          (studentId) async => switch (studentId) {
            's1' => const Right([_payerNoPhone, _guardianWithPhone]),
            's2' => const Right([_payerNoPhone]),
            _ => const Left(StorageFailure('boom')),
          },
        );

        // L'ordre de l'écran est gardé.
        expect(recipients.map((r) => r.studentId), ['s1', 's2', 's3']);
        expect(recipients[0].parentName, 'MOKE Rose');
        expect(recipients[0].phoneNumber, '+243810000001');
        expect(recipients[1].parentName, 'MOKE Albert');
        expect(recipients[1].hasPhone, isFalse);
        // Une lecture en échec n'arrête pas la relance.
        expect(recipients[2].parentName, isNull);
        expect(recipients[2].studentName, 'KABONGO Prénoms3');
      },
    );
  });

  group('FeeControlNotifyPdf', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    });

    test(
      'se compose et part au partage sous « Relance des parents »',
      () async {
        Uint8List? bytes;
        String? name;
        await FeeControlNotifyPdf.share(
          (b, n) async {
            bytes = b;
            name = n;
          },
          schoolName: '',
          context: 'Minerval · 6e A',
          message: 'Cher parent…',
          recipients: const [
            FeeControlNotifyRecipient(studentId: 's1', studentName: 'MOKE J'),
          ],
          issuedOn: DateTime(2026, 11, 22),
          l10n: l10n,
        );
        expect(name, 'Relance des parents.pdf');
        expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      },
    );
  });
}
