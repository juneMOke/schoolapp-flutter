import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';

/// Le fond d'une ligne ne doit pas recouvrir son encre.
///
/// L'encre d'un `InkWell` (survol, focus, appui) se peint sur le `Material`
/// le plus proche, SOUS ses enfants. Un fond posé par un `Container` enfant
/// la masquait : les lignes teintées de la paie ne réagissaient plus ni à la
/// souris ni au clavier.
void main() {
  testWidgets('le fond est porté par le Material qui reçoit l’encre', (
    tester,
  ) async {
    const background = Color(0xFFEFE7D6);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EteeloColumnTableRow(
            widths: const [null],
            cells: const [Text('Ligne')],
            onTap: () {},
            background: background,
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.byType(InkWell), matching: find.byType(Material))
          .first,
    );
    expect(material.color, background);

    final boxes = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      ),
    );
    for (final box in boxes) {
      expect((box.decoration as BoxDecoration?)?.color, isNull);
    }
  });
}
