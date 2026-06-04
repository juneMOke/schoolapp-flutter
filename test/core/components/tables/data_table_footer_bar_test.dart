import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/data_table_footer_bar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  group('DataTableFooterBar', () {
    Future<void> pumpFooter(
      WidgetTester tester, {
      required DataTableFooterConfig config,
      double width = 900,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Scaffold(body: DataTableFooterBar(config: config)),
          ),
        ),
      );
    }

    testWidgets('affiche le range x-y of N unit en pagination', (tester) async {
      await pumpFooter(
        tester,
        config: DataTableFooterConfig(
          label: '10 results',
          total: 34,
          unit: 'students',
          pagination: DataTablePaginationConfig(
            currentPage: 2,
            totalPages: 4,
            pageSize: 10,
            onPrevious: () {},
            onNext: () {},
          ),
        ),
      );

      expect(find.text('11–20 of 34 students'), findsOneWidget);
      final rangeText = tester.widget<Text>(find.text('11–20 of 34 students'));
      expect(rangeText.style?.color, AppColors.textMuted);
    });

    testWidgets('affiche 1-total when no pagination is configured', (
      tester,
    ) async {
      await pumpFooter(
        tester,
        config: const DataTableFooterConfig(
          label: '7 results',
          total: 7,
          unit: 'students',
        ),
      );

      expect(find.text('1–7 of 7 students'), findsOneWidget);
    });

    testWidgets('retombe sur le label legacy quand total/unit absents', (
      tester,
    ) async {
      await pumpFooter(
        tester,
        config: const DataTableFooterConfig(label: '7 results'),
      );

      expect(find.text('7 results'), findsOneWidget);
    });
  });
}
