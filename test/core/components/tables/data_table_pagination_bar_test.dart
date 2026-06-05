import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/data_table_pagination_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  group('DataTablePaginationBar', () {
    Future<void> pumpPagination(
      WidgetTester tester, {
      required int currentPage,
      required int totalPages,
      bool isLoading = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: DataTablePaginationBar(
                currentPage: currentPage,
                totalPages: totalPages,
                onPrevious: () {},
                onNext: () {},
                isLoading: isLoading,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('applique l active-fill sur indicateur courant', (
      tester,
    ) async {
      await pumpPagination(tester, currentPage: 2, totalPages: 5);

      final pageText = tester.widget<Text>(find.text('Page 2 / 5'));
      final pageContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Page 2 / 5'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = pageContainer.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.bleuArdoise);
      expect(pageText.style?.color, AppColors.blancCasse);
    });

    testWidgets('desactive precedent en page 1 et suivant en derniere page', (
      tester,
    ) async {
      await pumpPagination(tester, currentPage: 1, totalPages: 3);

      final inkWellsFirst = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWellsFirst.first.onTap, isNull);
      expect(inkWellsFirst.last.onTap, isNotNull);

      await pumpPagination(tester, currentPage: 3, totalPages: 3);

      final inkWellsLast = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWellsLast.first.onTap, isNotNull);
      expect(inkWellsLast.last.onTap, isNull);
    });

    testWidgets('respecte bouton 32 et zone de tap 44', (tester) async {
      await pumpPagination(tester, currentPage: 2, totalPages: 5);

      final tapTargets = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == AppDimensions.paginationTapTarget &&
            widget.height == AppDimensions.paginationTapTarget,
      );
      expect(tapTargets, findsNWidgets(2));

      final squareButtons = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where(
            (container) =>
                container.constraints != null &&
                container.constraints!.maxWidth ==
                    AppDimensions.paginationButtonSize &&
                container.constraints!.maxHeight ==
                    AppDimensions.paginationButtonSize,
          );
      expect(squareButtons.length, 2);
    });

    testWidgets('expose landmark Pagination et liveRegion sur page courante', (
      tester,
    ) async {
      await pumpPagination(tester, currentPage: 2, totalPages: 5);

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );

      final hasPaginationLandmark = semanticsWidgets.any(
        (widget) => widget.properties.label == 'Pagination',
      );
      final hasLiveRegion = semanticsWidgets.any(
        (widget) =>
            widget.properties.liveRegion == true &&
            widget.properties.label == 'Page 2 / 5',
      );

      expect(hasPaginationLandmark, isTrue);
      expect(hasLiveRegion, isTrue);
    });
  });
}
