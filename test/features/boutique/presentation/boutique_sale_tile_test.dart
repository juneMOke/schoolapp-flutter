import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets('l\'heure de la vente se lit à l\'heure de l\'école', (
    tester,
  ) async {
    // 23 h 30 UTC le 29 = 0 h 30 le 30 à Kinshasa : un autre jour qu'aujourd'hui,
    // donc la date s'écrit avec l'heure.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BoutiqueSaleTile(
            sale: SaleHistoryEntry(
              id: 's-1',
              payerName: 'Ndombo Lelo Willy',
              amounts: MoneyBag.of(const [Money(1500, 'USD')]),
              soldAt: '2026-08-29T23:30:00Z',
              syncStatus: 'SYNCED',
              receiptNumber: 'RV-000472',
              articleCount: 2,
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('30/08 00:30'), findsOneWidget);
  });
}
