import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/export/fee_control_call_sheet_pdf.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La feuille d'appel à signer.
///
/// Deux choses se vérifient sans rendre une page : la règle des montants — on
/// n'additionne jamais deux devises — et le fait que le document se construise
/// dans les cas qui l'ont fait naître (aucun cours, sélection mixte, liste
/// longue).
FeeControlRow row(
  String id, {
  String lastName = 'MOKE',
  int expected = 22000,
  int paid = 0,
  String currency = 'USD',
  List<RecoveryChargePosition> extra = const [],
}) => FeeControlRow(
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
    charges: [
      RecoveryChargePosition(
        feeCode: 'TUITION',
        position: FeeChargePosition(
          currency: currency,
          expectedInCents: expected,
          paidMirrorInCents: paid,
          paidPendingInCents: 0,
        ),
      ),
      ...extra,
    ],
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  group('la règle des montants', () {
    test('une devise : un montant', () {
      expect(
        FeeControlCallSheetPdf.moneyCell(
          MoneyBag.from(const Money(22000, 'USD')),
        ),
        '220,00\u00A0\$',
      );
    });

    test('deux devises : juxtaposées, JAMAIS sommées', () {
      final cell = FeeControlCallSheetPdf.moneyCell(
        MoneyBag.of(const [Money(22000, 'USD'), Money(4500000, 'CDF')]),
      );
      // Le signataire voit deux dettes distinctes. Un total n'existerait pas.
      expect(cell, contains('+'));
      expect(cell, contains('220,00'));
      expect(cell, contains('FC'));
    });

    test('aucune créance : un tiret, pas un zéro', () {
      // « Aucune créance » n'est pas « zéro dollar ».
      expect(FeeControlCallSheetPdf.moneyCell(MoneyBag.empty), '—');
    });
  });

  group('le document se construit', () {
    Future<int> bytesFor(List<FeeControlRow> rows, {ExchangeRate? rate}) async {
      final bytes = await FeeControlCallSheetPdf.build(
        rows: rows,
        context: 'Scolarité · 1ère A',
        academicYearLabel: '2026-2027',
        issuedOn: DateTime(2026, 9, 10),
        rate: rate,
        l10n: l10n,
      );
      return bytes.length;
    }

    test('sans cours du jour — la mention tombe, la feuille reste', () async {
      expect(await bytesFor([row('0142')]), greaterThan(0));
    });

    test('avec un cours, la mention légale s\'imprime', () async {
      expect(
        await bytesFor(
          [row('0142')],
          rate: ExchangeRate(
            base: 'USD',
            quote: 'CDF',
            rateMicros: 2850 * ExchangeRate.scale,
            effectiveFrom: DateTime(2026),
          ),
        ),
        greaterThan(0),
      );
    });

    test('sélection mixte : deux devises dans la même cellule', () async {
      expect(
        await bytesFor([
          row(
            '0142',
            extra: [
              const RecoveryChargePosition(
                feeCode: 'REGISTRATION',
                position: FeeChargePosition(
                  currency: 'CDF',
                  expectedInCents: 4500000,
                  paidMirrorInCents: 0,
                  paidPendingInCents: 0,
                ),
              ),
            ],
          ),
        ]),
        greaterThan(0),
      );
    });

    test('une liste longue déborde sur plusieurs pages sans lever', () async {
      final rows = [for (var i = 0; i < 60; i++) row('$i', lastName: 'NOM$i')];
      expect(await bytesFor(rows), greaterThan(0));
    });
  });
}
