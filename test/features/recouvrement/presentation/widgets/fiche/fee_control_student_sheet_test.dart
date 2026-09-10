import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_student_sheet.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aperçu d'un élève : ses frais, un par un, chacun dans sa devise.
///
/// ⚠️ Harnais sous `AppTheme.light`, et ce n'est pas décoratif : le pied de
/// cette modale pose deux boutons inline. Sans le vrai thème, un oubli de
/// `minimumSize` la ferait sortir SANS TAILLE, et rien ne le dirait ici.
const tTariffs = [
  LocalFeeTariff(
    id: 't-1',
    feeCode: 'TUITION',
    label: 'Scolarité annuelle',
    amountInCents: 22000,
    currency: 'USD',
  ),
];

FeeControlRow buildRow({List<RecoveryChargePosition> charges = const []}) =>
    FeeControlRow(
      summary: const EnrollmentSummary(
        enrollmentId: 'enr-1',
        enrollmentCode: 'EL-0158',
        status: 'COMPLETED',
        syncState: SyncState.synced,
        schoolLevelName: '1ère année',
        schoolLevelGroupName: 'Primaire',
        student: StudentSummary(
          id: 's1',
          firstName: 'Bope',
          lastName: 'NSIMBA',
          surname: 'Junior',
          dateOfBirth: '2010-01-01',
          gender: Gender.male,
        ),
      ),
      line: LocalRecoveryLine(
        schoolLevelId: 'lvl-1',
        studentId: 's1',
        charges: charges.isEmpty
            ? const [
                RecoveryChargePosition(
                  feeCode: 'TUITION',
                  position: FeeChargePosition(
                    currency: 'USD',
                    expectedInCents: 22000,
                    paidMirrorInCents: 6000,
                    paidPendingInCents: 0,
                  ),
                ),
              ]
            : charges,
      ),
    );

void main() {
  late int marks;
  late int records;

  setUp(() {
    marks = 0;
    records = 0;
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required FeeControlRow row,
    bool marked = false,
  }) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeeControlStudentSheet(
          row: row,
          tariffs: tTariffs,
          rate: null,
          marked: marked,
          onToggleMark: () => marks++,
          onOpenRecord: () => records++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la fiche a une taille, et nomme l\'élève et son dossier', (
    tester,
  ) async {
    await pumpSheet(tester, row: buildRow());

    expect(tester.takeException(), isNull);
    // `getSize` lève de lui-même sur une boîte sans taille : c'est la garde
    // contre le bouton inline à largeur infinie.
    expect(tester.getSize(find.byType(Dialog)).isEmpty, isFalse);
    expect(find.text('NSIMBA Bope'), findsOneWidget);
    expect(find.text('Dossier EL-0158'), findsOneWidget);
    expect(find.text('1ÈRE ANNÉE · PRIMAIRE'), findsOneWidget);
  });

  testWidgets('chaque frais dit son avancement, nommé par la grille', (
    tester,
  ) async {
    await pumpSheet(tester, row: buildRow());

    expect(find.text('Scolarité annuelle'), findsOneWidget);
    // 60 payés sur 220 → 27 %, et le reste s'écrit parce qu'il en reste.
    expect(find.textContaining('27 %'), findsOneWidget);
    expect(find.textContaining('reste'), findsOneWidget);
  });

  testWidgets('un frais soldé n\'affiche PAS « reste 0 »', (tester) async {
    await pumpSheet(
      tester,
      row: buildRow(
        charges: const [
          RecoveryChargePosition(
            feeCode: 'TUITION',
            position: FeeChargePosition(
              currency: 'USD',
              expectedInCents: 22000,
              paidMirrorInCents: 22000,
              paidPendingInCents: 0,
            ),
          ),
        ],
      ),
    );

    // « reste 0 $ » n'apprend rien et brouille les lignes qui comptent.
    expect(find.textContaining('reste'), findsNothing);
    expect(find.textContaining('100 %'), findsOneWidget);
  });

  testWidgets('deux devises : la note dit qu\'elles ne s\'additionnent pas', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      row: buildRow(
        charges: const [
          RecoveryChargePosition(
            feeCode: 'TUITION',
            position: FeeChargePosition(
              currency: 'USD',
              expectedInCents: 22000,
              paidMirrorInCents: 6000,
              paidPendingInCents: 0,
            ),
          ),
          RecoveryChargePosition(
            feeCode: 'REGISTRATION',
            position: FeeChargePosition(
              currency: 'CDF',
              expectedInCents: 4500000,
              paidMirrorInCents: 4500000,
              paidPendingInCents: 0,
            ),
          ),
        ],
      ),
    );

    expect(find.textContaining('ne s\'additionnent pas'), findsOneWidget);
  });

  testWidgets('le pied bascule le marquage et mène à la fiche complète', (
    tester,
  ) async {
    await pumpSheet(tester, row: buildRow());

    expect(find.text('Marquer à renvoyer'), findsOneWidget);
    await tester.tap(find.text('Marquer à renvoyer'));
    await tester.pumpAndSettle();
    expect(marks, 1);

    await tester.tap(find.text('Ouvrir la fiche complète'));
    await tester.pumpAndSettle();
    expect(records, 1);
  });

  testWidgets('déjà marqué : le bouton propose de retirer', (tester) async {
    await pumpSheet(tester, row: buildRow(), marked: true);

    expect(find.text('Retirer des renvois'), findsOneWidget);
    expect(find.text('Marquer à renvoyer'), findsNothing);
  });
}
