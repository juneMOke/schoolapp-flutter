import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_option_tile.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_classroom_select.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le champ **Classe** unique (spec v2, R2) : toutes les classes de l'année,
/// rangées par cycle puis par niveau, et la rubrique « Non affectés » en
/// dernier.
const _groups = [
  // Déclarés dans le désordre : c'est `displayOrder` qui range.
  SchoolLevelGroupBundle(
    group: SchoolLevelGroup(
      id: 'g-sec',
      name: 'Secondaire',
      code: 'SEC',
      displayOrder: 2,
    ),
    levels: [
      SchoolLevel(
        id: 'l-7',
        name: '7ème',
        code: 'S7',
        displayOrder: 1,
        splitIntoClassrooms: true,
      ),
    ],
  ),
  SchoolLevelGroupBundle(
    group: SchoolLevelGroup(
      id: 'g-prim',
      name: 'Primaire',
      code: 'PRIM',
      displayOrder: 1,
    ),
    levels: [
      SchoolLevel(
        id: 'l-1',
        name: '1ère',
        code: 'P1',
        displayOrder: 1,
        splitIntoClassrooms: true,
      ),
      SchoolLevel(
        id: 'l-2',
        name: '2ème',
        code: 'P2',
        displayOrder: 2,
        splitIntoClassrooms: true,
      ),
    ],
  ),
];

OfflineClassroom _room(String id, String name, String? group, String? level) =>
    OfflineClassroom(
      id: id,
      academicYearId: 'ay-1',
      schoolLevelGroupId: group,
      schoolLevelId: level,
      name: name,
    );

/// Arrivées dans l'ordre de la base, qui n'est pas celui de l'école.
final _classrooms = [
  _room('c-7a', '7ème A', 'g-sec', 'l-7'),
  _room('c-2a', '2ème A', 'g-prim', 'l-2'),
  _room('c-1b', '1ère B', 'g-prim', 'l-1'),
  _room('c-x', 'Atelier', null, null),
  _room('c-1a', '1ère A', 'g-prim', 'l-1'),
];

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? value,
    ValueChanged<String>? onChanged,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 360,
              child: FeeControlClassroomSelect(
                classrooms: _classrooms,
                groups: _groups,
                value: value,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> optionLabels(WidgetTester tester) => [
    for (final item
        in tester
            .widget<EteeloSelectInput<String>>(
              find.byType(EteeloSelectInput<String>),
            )
            .items)
      item.label,
  ];

  testWidgets('les options sont rangées par cycle puis par niveau, nommées '
      '« classe · cycle », et « Non affectés » ferme la liste', (tester) async {
    await pump(tester);

    expect(optionLabels(tester), [
      '1ère A · Primaire',
      '1ère B · Primaire',
      '2ème A · Primaire',
      '7ème A · Secondaire',
      // Sans cycle connu : après les classes rangées, nommée seule.
      'Atelier',
      'Non affectés',
    ]);
  });

  testWidgets('« Non affectés » porte la valeur de fil du serveur', (
    tester,
  ) async {
    await pump(tester);

    final items = tester
        .widget<EteeloSelectInput<String>>(
          find.byType(EteeloSelectInput<String>),
        )
        .items;
    expect(items.last.value, feeControlUnassigned);
  });

  testWidgets('choisir une option la remonte, « Non affectés » compris', (
    tester,
  ) async {
    final picked = <String>[];
    await pump(tester, onChanged: picked.add);

    await tester.tap(find.byType(EteeloSelectField));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(EteeloSelectOptionTile<String>, 'Non affectés'),
    );
    await tester.pumpAndSettle();

    expect(picked, [feeControlUnassigned]);
  });

  testWidgets('la classe choisie s\'affiche sous son nom complet', (
    tester,
  ) async {
    await pump(tester, value: 'c-7a');

    expect(find.text('7ème A · Secondaire'), findsOneWidget);
  });
}
