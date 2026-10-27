import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

/// Ce que la modale a rendu en se refermant.
class _Result {
  PresenceReportChoice? choice;
}

PresenceRowView _person(String id, String name) => PresenceRowView(
  personId: id,
  firstName: name,
  lastName: name,
  title: name,
  subtitle: 'Enseignant',
  status: PresenceStatus.none,
);

/// La modale de validation d'un registre, en carte : la liste des non
/// pointés, et un choix explicite sur leur sort avant de valider.
void main() {
  Future<_Result> open(
    WidgetTester tester,
    List<PresenceRowView> unmarked, {
    bool optional = true,
  }) async {
    final result = _Result();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result.choice = await EteeloCardDialog.show(
                    context,
                    PresenceReportDialog(
                      dayLabel: 'Mardi 27 octobre 2026',
                      title: 'Valider le rapport du jour',
                      present: 10,
                      late: 1,
                      absent: 2,
                      unmarked: unmarked,
                      unjustified: 0,
                      unmarkedOptional: optional,
                      unmarkedLabel: optional
                          ? null
                          : 'Ils seront marqués présents',
                      lockMessage: 'La validation verrouille la journée.',
                      confirmLabel: 'Valider',
                    ),
                  ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return result;
  }

  EteeloButton validate(WidgetTester tester) => tester.widget<EteeloButton>(
    find.ancestor(
      of: find.text('Valider'),
      matching: find.byType(EteeloButton),
    ),
  );

  final people = [_person('m-1', 'Kalala'), _person('m-2', 'Mayala')];

  testWidgets('une carte : la date en tête, la liste des non pointés', (
    tester,
  ) async {
    await open(tester, people);

    expect(find.text('Mardi 27 octobre 2026'), findsOneWidget);
    expect(find.text('2 personnes pas encore pointées'), findsOneWidget);
    expect(find.text('Kalala'), findsOneWidget);
    expect(find.text('Mayala'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('« Valider » reste éteint tant que leur sort n\'est pas choisi', (
    tester,
  ) async {
    final result = await open(tester, people);
    expect(validate(tester).onPressed, isNull);
    expect(
      find.text('Choisissez d\'abord le sort des non-pointés.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Les laisser à pointer'));
    await tester.pumpAndSettle();
    expect(validate(tester).onPressed, isNotNull);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(result.choice?.markRemaining, isFalse);
    expect(result.choice?.reviewUnmarked, isFalse);
  });

  testWidgets('« Les marquer présents » les compte présents et les marque', (
    tester,
  ) async {
    final result = await open(tester, people);

    await tester.tap(find.text('Les marquer présents'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(result.choice?.markRemaining, isTrue);
  });

  testWidgets('sans choix possible (appel), « Valider » est prêt et la '
      'modale le dit', (tester) async {
    await open(tester, people, optional: false);

    expect(find.text('Les marquer présents'), findsNothing);
    expect(find.text('Ils seront marqués présents'), findsOneWidget);
    expect(validate(tester).onPressed, isNotNull);
  });

  testWidgets('personne à pointer : ni liste ni choix', (tester) async {
    await open(tester, const []);

    expect(find.textContaining('pas encore pointé'), findsNothing);
    expect(validate(tester).onPressed, isNotNull);
  });

  testWidgets('« Voir dans le registre » referme sans valider', (tester) async {
    final result = await open(tester, people);

    await tester.tap(find.text('Voir dans le registre'));
    await tester.pumpAndSettle();

    expect(result.choice?.reviewUnmarked, isTrue);
    expect(result.choice?.markRemaining, isFalse);
  });

  testAtReferenceFormats('la carte tient', (tester, format) async {
    await open(tester, [
      for (var i = 0; i < 8; i++) _person('m-$i', 'Agent $i'),
    ]);
    expect(find.byType(PresenceReportDialog), findsOneWidget);
  });
}
