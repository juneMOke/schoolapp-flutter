import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _classroomA = OfflineClassroom(
  id: 'c1',
  academicYearId: 'ay-1',
  schoolLevelId: 'l1',
  name: '5e A',
  capacity: 30,
  totalCount: 20,
  femaleCount: 11,
  maleCount: 9,
);

const _options = [
  ClassesListCycleOption(
    id: 'g1',
    label: 'Primaire',
    displayOrder: 1,
    levels: [
      ClassesListLevelOption(
        schoolLevelGroupId: 'g1',
        schoolLevelGroupName: 'Primaire',
        schoolLevelId: 'l1',
        label: '5ème',
        displayOrder: 1,
        splitIntoClassrooms: true,
        classrooms: [_classroomA],
      ),
      // Niveau non réparti : aucune classe à proposer.
      ClassesListLevelOption(
        schoolLevelGroupId: 'g1',
        schoolLevelGroupName: 'Primaire',
        schoolLevelId: 'l2',
        label: '6ème',
        displayOrder: 2,
        splitIntoClassrooms: false,
        classrooms: [],
      ),
    ],
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<ClassesListSearchRequest> onSearch,
  List<ClassesListCycleOption> options = _options,
  bool isSearching = false,
}) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: ClassesListSearchForm(
          options: options,
          isSearching: isSearching,
          onSearch: onSearch,
        ),
      ),
    ),
  );
  if (isSearching) {
    // Le bouton primaire porte un indicateur de chargement : `pumpAndSettle`
    // n'a alors jamais de dernière frame.
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ouvre sur « Par classe » : cascade à trois + affinage', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {});

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
    expect(find.text('RECHERCHER PAR'), findsOneWidget);
    expect(find.text('Par classe'), findsOneWidget);
    expect(find.text('Par identité'), findsOneWidget);
    // Cycle + niveau + classe.
    expect(find.byType(EteeloSelectInput<String>), findsNWidgets(3));
    // Le seul champ texte du mode classe est l'affinage facultatif.
    expect(find.byType(EteeloTextInput), findsOneWidget);
    expect(find.text('Affiner par nom (facultatif)'), findsOneWidget);
  });

  testWidgets('sans référentiel, ouvre sur l\'identité (seule porte ouverte)', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {}, options: const []);

    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    expect(find.byType(EteeloSelectInput<String>), findsNothing);
  });

  testWidgets('mode identité : trois champs, plus aucune liste', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {});
    await _switchToIdentity(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    expect(find.byType(EteeloSelectInput<String>), findsNothing);
  });

  testWidgets(
    'le niveau seul arme la recherche ; la classe reste facultative',
    (tester) async {
      ClassesListSearchRequest? captured;
      await _pump(tester, onSearch: (request) => captured = request);

      expect(_searchButton(tester).onPressed, isNull);

      await _selectCycle(tester);
      expect(
        _searchButton(tester).onPressed,
        isNull,
        reason: 'un cycle sans niveau n\'ouvre rien',
      );

      await _selectLevel(tester, '5ème');
      expect(_searchButton(tester).onPressed, isNotNull);

      await _search(tester);

      expect(captured!.mode, SearchMode.level);
      expect(captured!.selectedLevel?.schoolLevelId, 'l1');
      expect(captured!.selectedClassroom, isNull);
    },
  );

  testWidgets('la classe choisie voyage avec le niveau', (tester) async {
    ClassesListSearchRequest? captured;
    await _pump(tester, onSearch: (request) => captured = request);

    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    await tester.tap(find.byType(EteeloSelectField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5e A').last);
    await tester.pumpAndSettle();

    await _search(tester);

    expect(captured!.selectedClassroom?.id, 'c1');
    expect(captured!.targetsClassroom, isTrue);
  });

  testWidgets('un niveau non réparti laisse le sélecteur de classe éteint', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {});

    await _selectCycle(tester);
    await _selectLevel(tester, '6ème');

    final classroomSelect = tester.widget<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>).at(2),
    );
    expect(classroomSelect.enabled, isFalse);
    expect(find.text('Aucune classe pour ce niveau'), findsOneWidget);
  });

  testWidgets('changer de niveau relâche la classe du niveau précédent', (
    tester,
  ) async {
    ClassesListSearchRequest? captured;
    await _pump(tester, onSearch: (request) => captured = request);

    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    await tester.tap(find.byType(EteeloSelectField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5e A').last);
    await tester.pumpAndSettle();

    await _selectLevel(tester, '6ème');
    await _search(tester);

    expect(
      captured!.selectedClassroom,
      isNull,
      reason: 'la classe du 5ème ne doit pas partir avec le 6ème',
    );
  });

  testWidgets('identité : les trois noms sont requis pour armer', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {});
    await _switchToIdentity(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();
    expect(_searchButton(tester).onPressed, isNull);

    await _enterNames(tester);
    expect(_searchButton(tester).onPressed, isNotNull);
  });

  testWidgets('identité : le niveau choisi dans l\'autre mode ne part pas', (
    tester,
  ) async {
    ClassesListSearchRequest? captured;
    await _pump(tester, onSearch: (request) => captured = request);

    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    await _switchToIdentity(tester);
    await _enterNames(tester);
    await _search(tester);

    expect(captured!.mode, SearchMode.identity);
    expect(captured!.firstName, 'Daniel');
    expect(captured!.lastName, 'Kabongo');
    expect(captured!.surname, 'Mwamba');
    // Un élève nommé ne doit pas se voir imposer en douce la classe restée
    // sélectionnée sous l'autre onglet.
    expect(captured!.selectedCycle, isNull);
    expect(captured!.selectedLevel, isNull);
    expect(captured!.selectedClassroom, isNull);
    expect(captured!.targetsClassroom, isFalse);
  });

  testWidgets('classe : les noms de l\'autre mode ne partent pas non plus', (
    tester,
  ) async {
    ClassesListSearchRequest? captured;
    await _pump(tester, onSearch: (request) => captured = request);

    await _switchToIdentity(tester);
    await _enterNames(tester);
    await _switchToClass(tester);
    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    await _search(tester);

    expect(captured!.selectedLevel?.schoolLevelId, 'l1');
    expect(captured!.firstName, isEmpty);
    expect(captured!.lastName, isEmpty);
    expect(captured!.surname, isEmpty);
  });

  testWidgets('classe : l\'affinage emprunte la colonne « Nom »', (
    tester,
  ) async {
    ClassesListSearchRequest? captured;
    await _pump(tester, onSearch: (request) => captured = request);

    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    // Le seul champ texte du mode classe.
    await tester.enterText(find.byType(TextField).first, 'kab');
    await tester.pumpAndSettle();
    await _search(tester);

    expect(captured!.lastName, 'Kab');
    expect(captured!.firstName, isEmpty);
    expect(captured!.surname, isEmpty);
    expect(
      captured!.hasAnyCriteria,
      isTrue,
      reason: 'c\'est le niveau qui ouvre, pas l\'affinage',
    );
  });

  testWidgets('« Effacer » vide les deux modes sans changer de mode', (
    tester,
  ) async {
    await _pump(tester, onSearch: (_) {});

    await _selectCycle(tester);
    await _selectLevel(tester, '5ème');
    expect(_searchButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Effacer'));
    await tester.pumpAndSettle();

    expect(_searchButton(tester).onPressed, isNull);
    // Toujours en mode classe : effacer ne renvoie pas ailleurs.
    expect(find.byType(EteeloSelectInput<String>), findsNWidgets(3));
  });

  testWidgets('recherche en vol : listes et actions sont éteintes', (
    tester,
  ) async {
    final emitted = <ClassesListSearchRequest>[];
    await _pump(tester, onSearch: emitted.add, isSearching: true);

    // ⚠️ Le bouton primaire garde volontairement un `onPressed` no-op pendant
    // le chargement (il conserve son apparence active) : c'est le fait de ne
    // RIEN émettre qui prouve qu'il est éteint, pas un callback nul.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 100));
    expect(emitted, isEmpty);

    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Effacer'))
          .onPressed,
      isNull,
    );
    final cycleSelect = tester.widget<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>).first,
    );
    expect(cycleSelect.enabled, isFalse);
  });
}

ElevatedButton _searchButton(WidgetTester tester) => tester
    .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Rechercher'));

Future<void> _search(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
  await tester.pumpAndSettle();
}

Future<void> _switchToIdentity(WidgetTester tester) async {
  await tester.tap(find.text('Par identité'));
  await tester.pumpAndSettle();
}

Future<void> _switchToClass(WidgetTester tester) async {
  await tester.tap(find.text('Par classe'));
  await tester.pumpAndSettle();
}

/// Ordre des champs (SearchNameFields) : Nom, Post-nom, Prénom.
Future<void> _enterNames(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Kabongo');
  await tester.enterText(fields.at(1), 'Mwamba');
  await tester.enterText(fields.at(2), 'Daniel');
  await tester.pumpAndSettle();
}

Future<void> _selectCycle(WidgetTester tester) async {
  await tester.tap(find.byType(EteeloSelectField).at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Primaire').last);
  await tester.pumpAndSettle();
}

Future<void> _selectLevel(WidgetTester tester, String label) async {
  await tester.tap(find.byType(EteeloSelectField).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
