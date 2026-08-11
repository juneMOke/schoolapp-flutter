import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/dev/dev_tools_entry.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ce fichier protège la **porte**, pas les écrans qu'elle ouvre.
///
/// La panne qu'il empêche est déjà arrivée : `/dev/components` et
/// `/dev/ticket-print` étaient déclarées dans le routeur et référencées nulle
/// part, donc inatteignables — pendant des mois pour la galerie, et au moment
/// exact où le banc de calage thermique devenait nécessaire. Rien ne cassait,
/// aucun test ne rougissait : une route orpheline est silencieuse.
///
/// Les destinations sont donc des pages factices **déclarées sous les mêmes
/// constantes** que le routeur réel. Ce qui est vérifié ici, c'est qu'un appui
/// pousse bien vers ces constantes-là, et que la pile permet d'en revenir.
void main() {
  late GoRouter router;

  Widget harness() {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: DevToolsEntry()),
        ),
        GoRoute(
          path: AppRoutesNames.ticketPrintBench,
          builder: (_, _) => const Scaffold(body: Text('BANC')),
        ),
        GoRoute(
          path: AppRoutesNames.componentGallery,
          builder: (_, _) => const Scaffold(body: Text('GALERIE')),
        ),
      ],
    );
    // Le vrai thème : c'est lui qui étirerait un `FilledButton` à toute la
    // largeur. La porte est faite de `TextButton` pour cette raison, et ce
    // harnais est ce qui le vérifie.
    return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  }

  testWidgets('offre les deux écrans de développement', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('Banc — impression thermique'), findsOneWidget);
    expect(find.text('Galerie de composants'), findsOneWidget);
  });

  testWidgets('ouvre le banc, et laisse revenir en arrière', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.text('Banc — impression thermique'));
    await tester.pumpAndSettle();

    expect(find.text('BANC'), findsOneWidget);
    // `push` et non `go` : sans pile, le retour système quitterait
    // l'application au lieu de ramener à l'accueil.
    expect(router.canPop(), isTrue);
  });

  testWidgets('ouvre la galerie de composants', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.text('Galerie de composants'));
    await tester.pumpAndSettle();

    expect(find.text('GALERIE'), findsOneWidget);
  });

  testWidgets('tient sur une seule ligne malgré le thème', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());

    // Deux boutons côte à côte, donc même ordonnée. Un `FilledButton` aurait
    // hérité de `minimumSize: Size(double.infinity, 56)` et les aurait empilés.
    final banc = tester.getTopLeft(find.text('Banc — impression thermique'));
    final galerie = tester.getTopLeft(find.text('Galerie de composants'));
    expect(banc.dy, galerie.dy);
  });
}
