import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

StudentCharge _charge({
  StudentChargeStatus status = StudentChargeStatus.partial,
  double expected = 30000,
  double paid = 18000,
}) {
  return StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: 't1',
    feeCode: 'TUITION',
    label: 'Frais de scolarité',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'USD',
    status: status,
  );
}

Future<void> _pumpInPageBackground(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FacturationChargeLine se rend dans AppPageBackground sans erreur de layout',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FacturationChargeLine(charge: _charge(), onViewRequested: () {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FacturationChargeLine), findsOneWidget);
    },
  );

  testWidgets(
    'FacturationChargeLine: liste de plusieurs lignes (tous statuts)',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final status in StudentChargeStatus.values)
              FacturationChargeLine(
                charge: _charge(status: status),
                onViewRequested: () {},
              ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byType(FacturationChargeLine),
        findsNWidgets(StudentChargeStatus.values.length),
      );
    },
  );
}
