import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_tri_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

/// Les parts dessinées, de gauche à droite.
List<Size> _parts(WidgetTester tester) => tester
    .widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(RecouvrementTriBar),
        matching: find.byType(ColoredBox),
      ),
    )
    .map((box) => tester.getSize(find.byWidget(box)))
    .toList();

void main() {
  group('la barre', () {
    testWidgets('chaque part a la hauteur de la barre — sans `stretch`, une '
        'part sans enfant tomberait à zéro et la barre serait invisible', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecouvrementTriBar(
          breakdown: FeeControlBreakdown(settled: 2, partial: 1, none: 1),
        ),
      );

      final parts = _parts(tester);
      expect(parts, hasLength(3));
      for (final part in parts) {
        expect(part.height, AppDimensions.recouvrementTriBarHeight);
      }
    });

    testWidgets('les parts sont à la proportion EXACTE des élèves', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecouvrementTriBar(
          breakdown: FeeControlBreakdown(settled: 2, partial: 1, none: 1),
        ),
      );

      final parts = _parts(tester);
      expect(parts[0].width, closeTo(parts[1].width * 2, 1));
      expect(parts[1].width, closeTo(parts[2].width, 1));
    });

    testWidgets('une part vide n\'est pas dessinée : un liseré pour zéro élève '
        'dirait qu\'il y en a', (tester) async {
      await _pump(
        tester,
        const RecouvrementTriBar(
          breakdown: FeeControlBreakdown(settled: 3, none: 1),
        ),
      );

      expect(_parts(tester), hasLength(2));
    });

    testWidgets('fine sous un cycle : la barre d\'un niveau', (tester) async {
      await _pump(
        tester,
        const RecouvrementTriBar(
          breakdown: FeeControlBreakdown(settled: 1, none: 1),
          dense: true,
        ),
      );

      for (final part in _parts(tester)) {
        expect(part.height, AppDimensions.recouvrementTriBarDenseHeight);
      }
    });
  });

  group('les comptes', () {
    testWidgets('les trois sont toujours écrits, zéro compris — « 0 rien '
        'payé » est une information', (tester) async {
      await _pump(
        tester,
        const RecouvrementTriCounts(breakdown: FeeControlBreakdown(settled: 3)),
      );

      expect(find.text('3 tout payé'), findsOneWidget);
      expect(find.text('0 partiellement'), findsOneWidget);
      expect(find.text('0 rien payé'), findsOneWidget);
      expect(find.text('3 élèves'), findsOneWidget);
    });

    testWidgets('l\'effectif s\'accorde au singulier', (tester) async {
      await _pump(
        tester,
        const RecouvrementTriCounts(breakdown: FeeControlBreakdown(partial: 1)),
      );

      expect(find.text('1 élève'), findsOneWidget);
    });
  });
}
