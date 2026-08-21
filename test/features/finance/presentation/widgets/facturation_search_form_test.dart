import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _options = [
  FacturationLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l1',
    label: 'Primaire - 1ère',
  ),
  FacturationLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l2',
    label: 'Primaire - 2ème',
  ),
  FacturationLevelOption(
    schoolLevelGroupId: 'g2',
    schoolLevelId: 'l3',
    label: 'Secondaire - 6ème',
  ),
];

Future<void> _pumpForm(
  WidgetTester tester, {
  required Size size,
  ValueChanged<FacturationSearchRequest>? onSearch,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationSearchForm(
          options: _options,
          isLoading: false,
          onSearch: onSearch ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in const {
    'compact (étroit)': Size(420, 900),
    'large': Size(1400, 900),
  }.entries) {
    testWidgets('rendu ${entry.key} : les deux modes tiennent dans la carte', (
      tester,
    ) async {
      await _pumpForm(tester, size: entry.value);

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      // Mode par défaut : la cascade, plus l'affinage facultatif.
      expect(find.byType(EteeloSelectInput<String>), findsNWidgets(2));
      expect(find.byType(EteeloTextInput), findsOneWidget);

      await tester.tap(find.text('Par identité'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EteeloTextInput), findsNWidgets(3));
      expect(find.byType(EteeloSelectInput<String>), findsNothing);
    });
  }

  testWidgets('la bascule est annoncée et son aide nomme l\'autre mode', (
    tester,
  ) async {
    await _pumpForm(tester, size: const Size(1400, 900));

    expect(find.text('RECHERCHER PAR'), findsOneWidget);
    expect(find.text('Par classe'), findsOneWidget);
    expect(find.text('Par identité'), findsOneWidget);
    expect(
      find.textContaining('basculez sur « Par identité »'),
      findsOneWidget,
    );
  });

  testWidgets('identité : les critères partent sans le niveau', (tester) async {
    FacturationSearchRequest? captured;
    await _pumpForm(
      tester,
      size: const Size(1400, 900),
      onSearch: (request) => captured = request,
    );

    await tester.tap(find.text('Par identité'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Kabongo');
    await tester.enterText(fields.at(1), 'Mwamba');
    await tester.enterText(fields.at(2), 'Daniel');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    expect(captured!.lastName, 'Kabongo');
    expect(captured!.surname, 'Mwamba');
    expect(captured!.firstName, 'Daniel');
    expect(captured!.schoolLevelGroupId, isEmpty);
    expect(captured!.schoolLevelId, isEmpty);
  });

  testWidgets('classe : le niveau part seul', (tester) async {
    FacturationSearchRequest? captured;
    await _pumpForm(
      tester,
      size: const Size(1400, 900),
      onSearch: (request) => captured = request,
    );

    // Les listes déroulantes du DS ouvrent un panneau en overlay : le test
    // invoque directement leur `onChanged`.
    final selects = tester
        .widgetList<EteeloSelectInput<String>>(
          find.byType(EteeloSelectInput<String>),
        )
        .toList(growable: false);
    selects[0].onChanged('g1');
    await tester.pumpAndSettle();
    tester
        .widgetList<EteeloSelectInput<String>>(
          find.byType(EteeloSelectInput<String>),
        )
        .toList(growable: false)[1]
        .onChanged('g1::l2');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    expect(captured!.schoolLevelGroupId, 'g1');
    expect(captured!.schoolLevelId, 'l2');
    expect(captured!.lastName, isEmpty);
  });
}
