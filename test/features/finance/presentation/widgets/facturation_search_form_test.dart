import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
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

Future<void> _pumpForm(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationSearchForm(
          options: _options,
          isLoading: false,
          onSearch: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'rendu compact (étroit) dans AppPageBackground sans erreur de layout',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      // Tous les champs nom utilisent EteeloTextInput (3 champs).
      expect(find.byType(EteeloTextInput), findsNWidgets(3));
    },
  );

  testWidgets(
    'rendu large (côte à côte) dans AppPageBackground sans erreur de layout',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      expect(find.byType(EteeloTextInput), findsNWidgets(3));
    },
  );
}
