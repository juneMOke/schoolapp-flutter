import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_rail_flyout.dart';

void main() {
  final menu = MenuItem(
    id: 'finances',
    title: 'Finances',
    icon: Icons.payments_outlined,
    subMenus: const [
      SubMenuItem(id: 'facturations', title: 'Facturations', route: '/f'),
      SubMenuItem(id: 'caisse', title: 'Caisse', route: '/c'),
    ],
  );

  testWidgets('le module se nomme, et le choix d’un écran le rend', (
    tester,
  ) async {
    SubMenuItem? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidebarRailFlyout(
            menu: menu,
            onSelected: (subMenu) => chosen = subMenu,
            builder: (context, toggle) =>
                IconButton(onPressed: toggle, icon: const Icon(Icons.menu)),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('FINANCES'), findsOneWidget);

    await tester.tap(find.text('Caisse'));
    await tester.pumpAndSettle();
    expect(chosen?.id, 'caisse');
    expect(find.text('Facturations'), findsNothing);
  });
}
