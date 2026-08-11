import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/dev/dev_tools_entry.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_module_card.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_sub_module_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La page d'accueil est montée sans `AuthBloc` ni `AcademicYearContextBloc` :
/// les lectures défensives du bandeau (salutation, année scolaire) doivent
/// tenir. Seule la `NavigationBloc` est indispensable — c'est elle que les
/// cartes pilotent.
void main() {
  late NavigationBloc navigationBloc;

  Widget buildHarness() {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          navigationBloc = NavigationBloc(AppLocalizations.of(context)!);
          return BlocProvider<NavigationBloc>.value(
            value: navigationBloc,
            // `AccueilPage` monte son propre Scaffold défilant
            // (`AppPageBackground`) : rien à ajouter autour.
            child: const AccueilPage(),
          );
        },
      ),
    );
  }

  Future<void> pumpAccueil(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
  }

  testWidgets('affiche les six cartes modules et annonce leur page d\'entrée', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAccueil(tester);

    expect(find.byType(AccueilModuleCard), findsNWidgets(6));

    // Le libellé d'accessibilité de l'en-tête nomme la destination réelle :
    // le tableau de bord quand il existe, sinon la première page du module.
    const entryByModule = {
      'Inscriptions': 'Tableau de bord',
      'Finances': 'Tableau de bord',
      'Classes': 'Tableau de bord',
      'Cours': 'Emploi du temps',
      'Résultats': 'Résultats par classe',
      'Disciplines': 'Tableau de bord',
    };
    for (final module in entryByModule.entries) {
      expect(
        find.bySemanticsLabel('${module.key} — ouvrir ${module.value}'),
        findsOneWidget,
        reason: 'carte « ${module.key} »',
      );
    }

    semantics.dispose();
  });

  testWidgets('annonce le nombre de pages de chaque module', (tester) async {
    await pumpAccueil(tester);

    // Inscriptions : tableau de bord + 3 pages. Résultats : page unique, au
    // singulier.
    expect(find.text('4 pages'), findsOneWidget);
    expect(find.text('1 page'), findsOneWidget);
    // Finances et Cours ont deux pages chacun.
    expect(find.text('2 pages'), findsNWidgets(2));
    // Classes et Disciplines en ont trois.
    expect(find.text('3 pages'), findsNWidgets(2));
  });

  testWidgets('l\'en-tête d\'une carte ouvre le tableau de bord du module', (
    tester,
  ) async {
    await pumpAccueil(tester);

    await tester.tap(find.text('Inscriptions'));
    await tester.pumpAndSettle();

    expect(
      navigationBloc.state.selectedMenuId,
      MenuConstants.inscriptionsMenuId,
    );
    expect(
      navigationBloc.state.selectedSubMenuId,
      MenuConstants.inscriptionsDashboardId,
    );
  });

  testWidgets('un module sans tableau de bord ouvre son premier sous-module', (
    tester,
  ) async {
    await pumpAccueil(tester);

    // Cours n'a pas de tableau de bord : la page d'entrée est « Emploi du
    // temps » (spec §03, note « page d'entrée »).
    await tester.tap(find.text('Cours'));
    await tester.pumpAndSettle();

    expect(navigationBloc.state.selectedMenuId, MenuConstants.coursesMenuId);
    expect(navigationBloc.state.selectedSubMenuId, MenuConstants.timetableId);
  });

  testWidgets('une ligne sous-module navigue vers son propre écran', (
    tester,
  ) async {
    await pumpAccueil(tester);

    await tester.tap(find.text('Pré-inscriptions'));
    await tester.pumpAndSettle();

    // La ligne absorbe le tap : on atterrit sur le sous-écran, pas sur le
    // tableau de bord de la carte parente.
    expect(
      navigationBloc.state.selectedSubMenuId,
      MenuConstants.preInscriptionsId,
    );
  });

  testWidgets('chaque page de chaque module a sa ligne dans un pied de carte', (
    tester,
  ) async {
    await pumpAccueil(tester);

    // 4 + 2 + 3 + 2 + 1 + 3 sous-modules (spec §03).
    expect(find.byType(AccueilSubModuleRow), findsNWidgets(15));
  });

  /// L'accueil est le **seul** chemin vers `/dev/components` et
  /// `/dev/ticket-print` : les deux routes existent dans le routeur mais ne
  /// sont référencées que par cette porte. La retirer d'ici les rendrait
  /// silencieusement inatteignables — ce qu'elles ont déjà été.
  ///
  /// Le test tient en debug comme en release : `flutter test` s'exécute
  /// toujours avec `kDebugMode` à `true`, valeur sous laquelle la porte est
  /// montée. La production, elle, la voit disparaître au const-folding.
  testWidgets('porte les outils de développement en bas de page', (
    tester,
  ) async {
    await pumpAccueil(tester);

    expect(find.byType(DevToolsEntry), findsOneWidget);
  });
}
