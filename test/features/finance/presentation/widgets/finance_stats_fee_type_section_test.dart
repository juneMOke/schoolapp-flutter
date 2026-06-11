import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_fee_type_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FeeTypeDistribution _distribution(List<FeeTypeItem> items) =>
    FeeTypeDistribution(items: items);

FeeTypeItem _item({
  required String code,
  int collected = 18000,
  int expected = 30000,
  int rate = 60,
}) {
  return FeeTypeItem(
    code: code,
    collected: collected,
    expected: expected,
    collectionRate: rate,
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
    'affiche le libellé localisé du type de frais, pas le code brut (phase 6)',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        FinanceStatsFeeTypeSection(
          distribution: _distribution([_item(code: 'TUITION')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Le code connu doit être rendu via son libellé localisé...
      expect(find.text('Frais de scolarité'), findsOneWidget);
      // ...et jamais sous sa forme brute.
      expect(find.text('TUITION'), findsNothing);
    },
  );

  testWidgets(
    'repli sur le code brut quand le type est inconnu (pas le libellé générique)',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        FinanceStatsFeeTypeSection(
          distribution: _distribution([_item(code: 'MYSTERY_FEE')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Un type inconnu garde son code (sinon tous les inconnus se
      // confondraient sous « Frais scolaire »).
      expect(find.text('MYSTERY_FEE'), findsOneWidget);
      expect(find.text('Frais scolaire'), findsNothing);
    },
  );
}
