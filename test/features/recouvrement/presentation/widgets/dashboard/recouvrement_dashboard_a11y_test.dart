import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_key_figures_band.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_breakdown_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le tableau de bord dit à qui ne le voit pas.
///
/// Un écran de mesure est le plus exposé de tous à l'inaccessibilité : ses
/// chiffres vivent dans des barres, et une barre ne se lit pas. Les tests
/// voisins vérifient le TEXTE affiché ; ceux-ci vérifient ce qui part au
/// lecteur d'écran — qui n'est pas la même chose, et que rien d'autre ne
/// couvre.
class _MockDashboardBloc
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {}

/// Un test qui a besoin de l'arbre sémantique.
///
/// Le handle se rend **dans le corps du test** : la vérification des
/// `SemanticsHandle` du framework court avant les `addTearDown`, et un handle
/// rendu là est déjà trop tard — le test échoue sur la plomberie plutôt que sur
/// ce qu'il éprouve.
void testSemantics(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      handle.dispose();
    }
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

const _primaire = FeeControlBreakdown(settled: 26, partial: 3, none: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('une ligne de cycle', () {
    testSemantics('s\'annonce d\'UNE phrase — le nom, les trois comptes, la '
        'part — et jamais en fragments', (tester) async {
      await tester.pumpWidget(
        _host(
          RecouvrementBreakdownTile(
            label: 'Primaire',
            breakdown: _primaire,
            onToggle: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Primaire')),
        isSemantics(
          label:
              'Primaire : 26 sur 31 élèves ont tout payé (84 %), 3 en partie, '
              '2 rien',
        ),
      );
    });

    testSemantics('la barre et ses comptes n\'ont pas de nœud à eux : ils sont '
        'DANS la phrase de la ligne', (tester) async {
      await tester.pumpWidget(
        _host(
          RecouvrementBreakdownTile(
            label: 'Primaire',
            breakdown: _primaire,
            onToggle: () {},
          ),
        ),
      );

      // Le texte « 26 tout payé » remonte au nœud de la ligne : un lecteur
      // d'écran ne l'épellera pas une seconde fois, hors de son contexte.
      expect(
        tester.getSemantics(find.text('26 tout payé')).label,
        startsWith('Primaire : '),
      );
    });

    testSemantics('porte une ACTION, pas seulement le rôle de bouton — sans '
        'quoi la double-tape d\'un lecteur d\'écran n\'ouvre rien', (
      tester,
    ) async {
      var toggled = 0;
      await tester.pumpWidget(
        _host(
          RecouvrementBreakdownTile(
            label: 'Primaire',
            breakdown: _primaire,
            onToggle: () => toggled++,
          ),
        ),
      );

      final node = tester.getSemantics(find.text('Primaire'));
      expect(
        node,
        isSemantics(
          isButton: true,
          hasTapAction: true,
          // Le geste se nomme : « bouton » seul ne dit pas ce qu'il ouvre.
          hint: 'Voir les niveaux de ce cycle',
        ),
      );

      // Contre-épreuve : l'action annoncée doit réellement ouvrir.
      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(toggled, 1);
    });

    testSemantics('ouverte, le geste annoncé est celui du REPLI', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RecouvrementBreakdownTile(
            label: 'Primaire',
            breakdown: _primaire,
            expanded: true,
            onToggle: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Primaire')),
        isSemantics(hint: 'Masquer les niveaux'),
      );
    });
  });

  group('une ligne de niveau', () {
    testSemantics('hors de son œil, elle s\'annonce SANS action : un bouton '
        'qui n\'ouvre rien est pire qu\'aucun bouton', (tester) async {
      await tester.pumpWidget(
        _host(
          const RecouvrementBreakdownTile(
            label: '1ère année',
            breakdown: FeeControlBreakdown(settled: 1, none: 3),
            dense: true,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('1ère année')),
        isSemantics(isButton: false, hasTapAction: false),
      );
    });

    testSemantics('l\'œil est un nœud À PART, et il nomme le niveau qu\'il '
        'ouvre', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          RecouvrementBreakdownTile(
            label: '1ère année',
            breakdown: const FeeControlBreakdown(settled: 5, none: 5),
            dense: true,
            onView: () => opened++,
          ),
        ),
      );

      // Hors du sous-arbre exclu, sans quoi il disparaîtrait de l'arbre
      // sémantique : la ligne s'annoncerait, mais l'action resterait
      // inatteignable. Le nom voyage par l'infobulle — un `tooltip`, pas un
      // `label`.
      final node = tester.getSemantics(find.byType(IconButton));
      expect(
        node,
        isSemantics(tooltip: 'Voir le détail : 1ère année', hasTapAction: true),
      );

      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(opened, 1);
    });
  });

  group('le bandeau', () {
    testSemantics('s\'annonce comme une synthèse, et non comme quatre nombres '
        'orphelins', (tester) async {
      final bloc = _MockDashboardBloc();
      final state = RecouvrementDashboardState(
        status: EnrollmentLoadStatus.success,
        figures: RecouvrementKeyFigures(
          total: 31,
          none: 2,
          partial: 3,
          settled: 26,
          expected: MoneyBag.of([Money.parse(930000, 'USD')]),
          paid: MoneyBag.of([Money.parse(800000, 'USD')]),
          remaining: MoneyBag.of([Money.parse(130000, 'USD')]),
        ),
      );
      when(() => bloc.state).thenReturn(state);
      whenListen(
        bloc,
        const Stream<RecouvrementDashboardState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(
        _host(
          BlocProvider<RecouvrementDashboardBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(
              child: RecouvrementKeyFiguresBand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bandeau se dit d'un seul nœud : son nom D'ABORD, puis les quatre
      // chiffres. Sans le nom en tête, le lecteur d'écran attaquerait par un
      // montant sans sujet.
      final node = tester.getSemantics(find.byType(EteeloKpiBand));
      expect(node.label, startsWith('Chiffres clés du recouvrement'));
      expect(node.label, contains('Attendu sur ces frais'));
      expect(node.label, contains('Perçu à ce jour'));
      expect(node.label, contains('N\'ont rien payé'));
    });
  });
}
