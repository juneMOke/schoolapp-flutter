import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _options = [
  SearchLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l1',
    label: 'Primaire - 1ère',
  ),
  SearchLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l2',
    label: 'Primaire - 2ème',
  ),
];

const _tariffs = [
  LocalFeeTariff(
    id: 't1',
    feeCode: 'TUITION',
    label: 'Frais scolaire',
    amountInCents: 150000,
    currency: 'USD',
  ),
];

const _classrooms = [
  OfflineClassroom(
    id: 'cls-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'l1',
    name: '1ère A',
    totalCount: 0,
    femaleCount: 0,
    maleCount: 0,
  ),
];

Future<void> _pumpForm(
  WidgetTester tester, {
  List<LocalFeeTariff> tariffs = const <LocalFeeTariff>[],
  List<OfflineClassroom> classrooms = const <OfflineClassroom>[],
  bool feeGridMissing = false,
  void Function(String, String)? onLevelSelected,
  ValueChanged<FeeControlSearchRequest>? onSearch,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FeeControlSearchForm(
          options: _options,
          tariffs: tariffs,
          classrooms: classrooms,
          isTariffsLoading: false,
          isClassroomsLoading: false,
          feeGridMissing: feeGridMissing,
          isLoading: false,
          onLevelSelected: onLevelSelected ?? (_, _) {},
          onSearch: onSearch ?? (_) {},
          onClear: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le bouton primaire « Rechercher » du formulaire.
Finder get _searchButton => find.ancestor(
  of: find.text('Rechercher'),
  matching: find.byType(ElevatedButton),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rendu étroit sans erreur de layout', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    // Cycle, Niveau, Classe, Frais + le statut (typé à part).
    expect(find.byType(EteeloSelectInput<String>), findsNWidgets(4));
    expect(
      find.byType(EteeloSelectInput<FeeControlPaymentFilter>),
      findsOneWidget,
    );
  });

  testWidgets('rendu large sans erreur de layout', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
  });

  testWidgets('Rechercher est éteint tant qu\'aucun frais n\'est choisi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    final button = tester.widget<ElevatedButton>(_searchButton);
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'choisir un cycle puis un niveau demande la grille du niveau',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selected = <String>[];
      await _pumpForm(
        tester,
        onLevelSelected: (groupId, levelId) =>
            selected.add('$groupId::$levelId'),
      );

      await _selectCycle(tester, 'g1');
      expect(selected, isEmpty, reason: 'un cycle seul ne charge pas la grille');

      await _selectLevel(tester, 'g1::l1');
      expect(selected, ['g1::l1']);
    },
  );

  testWidgets('un frais choisi arme Rechercher et remonte le code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    FeeControlSearchRequest? emitted;
    await _pumpForm(
      tester,
      tariffs: _tariffs,
      onSearch: (request) => emitted = request,
    );

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');

    expect(tester.widget<ElevatedButton>(_searchButton).onPressed, isNotNull);

    await tester.tap(_searchButton);
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.schoolLevelId, 'l1');
    expect(emitted!.schoolLevelGroupId, 'g1');
    expect(emitted!.feeCode, 'TUITION');
    expect(emitted!.statusFilter, FeeControlPaymentFilter.all);
  });

  testWidgets('la classe choisie descend dans les critères', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    FeeControlSearchRequest? emitted;
    await _pumpForm(
      tester,
      tariffs: _tariffs,
      classrooms: _classrooms,
      onSearch: (request) => emitted = request,
    );

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');

    // Défaut : toutes les classes du niveau.
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, isNull);

    await _selectClassroom(tester, 'cls-1');
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, 'cls-1');

    // La sentinelle « toutes les classes » revient bien à null.
    await _selectClassroom(
      tester,
      FeeControlClassroomField.allClassroomsValue,
    );
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, isNull);
  });

  testWidgets('changer de niveau désarme le frais déjà choisi', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');
    expect(tester.widget<ElevatedButton>(_searchButton).onPressed, isNotNull);

    await _selectLevel(tester, 'g1::l2');

    expect(
      tester.widget<ElevatedButton>(_searchButton).onPressed,
      isNull,
      reason: 'la grille du nouveau niveau n\'est pas encore connue',
    );
  });

  testWidgets(
    'grille absente de l\'appareil : message distinct de « aucun frais »',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true);

      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(
        find.textContaining('grille tarifaire n\'est pas encore descendue'),
        findsOneWidget,
      );
      expect(find.textContaining('Aucun frais n\'est défini'), findsNothing);
    },
  );

  testWidgets('niveau sans frais : message d\'information', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester);

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');

    expect(find.textContaining('Aucun frais n\'est défini'), findsOneWidget);
  });
}

// ─── Pilotage des sélecteurs ──────────────────────────────────────────────────
//
// Les listes déroulantes du DS ouvrent un panneau en overlay : le test invoque
// directement leur `onChanged` plutôt que de simuler l'ouverture, ce qui teste
// la logique du formulaire sans dépendre du rendu du panneau.

List<EteeloSelectInput<String>> _stringSelects(WidgetTester tester) => tester
    .widgetList<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    )
    .toList(growable: false);

Future<void> _selectCycle(WidgetTester tester, String groupId) async {
  _stringSelects(tester)[0].onChanged(groupId);
  await tester.pumpAndSettle();
}

Future<void> _selectLevel(WidgetTester tester, String levelKey) async {
  _stringSelects(tester)[1].onChanged(levelKey);
  await tester.pumpAndSettle();
}

Future<void> _selectClassroom(WidgetTester tester, String value) async {
  _stringSelects(tester)[2].onChanged(value);
  await tester.pumpAndSettle();
}

Future<void> _selectFee(WidgetTester tester, String feeCode) async {
  _stringSelects(tester)[3].onChanged(feeCode);
  await tester.pumpAndSettle();
}
