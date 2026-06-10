import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_pending_distribution_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required ClassroomStatus overviewStatus,
    bool isDistributing = false,
    int studentsToDistribute = 24,
    int maleCount = 13,
    int femaleCount = 11,
    VoidCallback? onDistributionRequested,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassesOrganisationPendingDistributionCard(
              isDistributing: isDistributing,
              overviewStatus: overviewStatus,
              levelName: '5e',
              studentsToDistribute: studentsToDistribute,
              maleCount: maleCount,
              femaleCount: femaleCount,
              onDistributionRequested: onDistributionRequested ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('affiche titre, effectif et pastilles G/F quand chargé', (
    tester,
  ) async {
    await pumpCard(tester, overviewStatus: ClassroomStatus.success);

    expect(find.text('Niveau pas encore réparti'), findsOneWidget);
    expect(find.text('G · 13'), findsOneWidget);
    expect(find.text('F · 11'), findsOneWidget);
    // Le message rappelle l'effectif et le niveau.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').contains('24') &&
            (widget.data ?? '').contains('5e'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le bouton primaire porte le libellé par genre et est actif', (
    tester,
  ) async {
    var tapped = 0;
    await pumpCard(
      tester,
      overviewStatus: ClassroomStatus.success,
      onDistributionRequested: () => tapped++,
    );

    final button = find.widgetWithText(
      FilledButton,
      'Lancer la répartition par genre',
    );
    expect(button, findsOneWidget);

    await tester.tap(button);
    expect(tapped, 1);
  });

  testWidgets(
    'pendant le chargement de l\'overview : spinner + bouton inactif',
    (tester) async {
      await pumpCard(tester, overviewStatus: ClassroomStatus.loading);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('pendant la répartition : bouton inactif', (tester) async {
    await pumpCard(
      tester,
      overviewStatus: ClassroomStatus.success,
      isDistributing: true,
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
