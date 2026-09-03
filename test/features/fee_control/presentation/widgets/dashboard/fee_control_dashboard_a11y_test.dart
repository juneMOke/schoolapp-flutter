import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_class_rows.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_group_row.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_summary_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le tableau de bord dit à qui ne le voit pas.
///
/// Un écran de mesure est le plus exposé de tous à l'inaccessibilité : ses
/// chiffres vivent dans des barres, et une barre ne se lit pas. Les tests
/// voisins vérifient le TEXTE affiché ; ceux-ci vérifient ce qui part au
/// lecteur d'écran — qui n'est pas la même chose, et que rien d'autre ne
/// couvre.
class _MockDashboardBloc
    extends MockBloc<FeeControlDashboardEvent, FeeControlDashboardState>
    implements FeeControlDashboardBloc {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('une ligne du classement', () {
    testSemantics('s\'annonce d\'UNE phrase — le nom, la part, l\'effectif — '
        'et jamais quatre fragments', (tester) async {
      await tester.pumpWidget(
        _host(
          FeeControlDashboardGroupRow(
            label: 'Primaire · 1ère année',
            breakdown: const FeeControlBreakdown(settled: 26, none: 5),
            onToggle: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Primaire · 1ère année')),
        isSemantics(
          label:
              'Primaire · 1ère année : 84 % en ordre, 26 sur 31 élèves '
              'concernés',
        ),
      );
    });

    testSemantics('porte une ACTION, pas seulement le rôle de bouton — sans '
        'quoi la double-tape d\'un lecteur d\'écran ne déplie rien', (
      tester,
    ) async {
      var toggled = 0;
      await tester.pumpWidget(
        _host(
          FeeControlDashboardGroupRow(
            label: '1ère année',
            breakdown: const FeeControlBreakdown(settled: 5, none: 5),
            onToggle: () => toggled++,
          ),
        ),
      );

      final node = tester.getSemantics(find.text('1ère année'));
      expect(
        node,
        isSemantics(
          isButton: true,
          hasTapAction: true,
          // Le geste se nomme : « bouton » seul ne dit pas ce qu'il ouvre.
          hint: 'Voir les classes de ce niveau',
        ),
      );

      // Contre-épreuve : l'action annoncée doit réellement déplier. C'est ce
      // que la double-tape déclenche, et c'est ce qui ne se passait pas.
      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(toggled, 1);
    });

    testSemantics('dépliée, le geste annoncé est celui du REPLI', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FeeControlDashboardGroupRow(
            label: '1ère année',
            breakdown: const FeeControlBreakdown(settled: 5, none: 5),
            expanded: true,
            onToggle: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('1ère année')),
        isSemantics(hint: 'Masquer les classes'),
      );
    });

    testSemantics('inerte, elle s\'annonce SANS action : un bouton qui '
        'n\'ouvre rien est pire qu\'aucun bouton', (tester) async {
      await tester.pumpWidget(
        _host(
          const FeeControlDashboardGroupRow(
            label: 'Niveau non renseigné',
            breakdown: FeeControlBreakdown(settled: 1, none: 3),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Niveau non renseigné')),
        isSemantics(isButton: false, hasTapAction: false),
      );
    });

    testSemantics('le passage vers les noms est un nœud À PART, et il se '
        'nomme', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          FeeControlDashboardGroupRow(
            label: '1ère année',
            breakdown: const FeeControlBreakdown(settled: 5, none: 5),
            onToggle: () {},
            onOpenControl: () => opened++,
          ),
        ),
      );

      // ⚠️ Enfermé dans le sous-arbre exclu, ce bouton disparaissait de l'arbre
      // sémantique : la ligne s'annonçait, mais l'action restait inatteignable.
      final node = tester.getSemantics(find.byType(IconButton));
      // Le nom voyage par l'infobulle du bouton — un `tooltip`, pas un `label`
      // — mais il voyage : le geste s'annonce.
      expect(node, isSemantics(tooltip: 'Voir les élèves', hasTapAction: true));

      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(opened, 1);
    });
  });

  group('le dépliage en classes', () {
    Widget classRows(EnrollmentLoadStatus status) =>
        FeeControlDashboardClassRows(
          status: status,
          classes: const <FeeControlClassRow>[],
          classroomsMissing: true,
          onOpenControl: null,
        );

    testSemantics('le chargement se NOMME : c\'est le seul retour que la tape '
        'donne à qui ne voit pas la barre', (tester) async {
      await tester.pumpWidget(_host(classRows(EnrollmentLoadStatus.loading)));

      expect(
        tester.getSemantics(find.byType(LinearProgressIndicator)),
        isSemantics(
          label: 'Chargement des classes de ce niveau…',
          isLiveRegion: true,
        ),
      );
    });

    testSemantics('la réponse au dépliage est une région VIVE : muette, elle '
        'laisserait croire que le geste n\'a rien fait', (tester) async {
      await tester.pumpWidget(_host(classRows(EnrollmentLoadStatus.failure)));

      expect(
        tester.getSemantics(
          find.text(
            'Les classes de ce niveau n\'ont pas pu être lues sur cet '
            'appareil.',
          ),
        ),
        isSemantics(isLiveRegion: true),
      );
    });
  });

  group('le bandeau', () {
    testSemantics('s\'annonce comme une synthèse, et non comme quatre nombres '
        'orphelins', (tester) async {
      final bloc = _MockDashboardBloc();
      const state = FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: FeeControlDashboardSummary(
          total: FeeControlBreakdown(settled: 26, partial: 3, none: 2),
          remaining: MoneyBag.empty,
          groups: <FeeControlGroupRow>[],
        ),
      );
      when(() => bloc.state).thenReturn(state);
      whenListen(
        bloc,
        const Stream<FeeControlDashboardState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(
        _host(
          BlocProvider<FeeControlDashboardBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(
              child: FeeControlDashboardSummaryBand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bandeau se dit d'un seul nœud : son nom D'ABORD, puis les quatre
      // nombres. Sans le nom en tête, le lecteur d'écran attaquerait par « 31 »
      // — un nombre sans sujet.
      final node = tester.getSemantics(find.byType(EteeloKpiBand));
      expect(node.label, startsWith('Synthèse du contrôle des frais'));
      expect(node.label, contains('Élèves concernés'));
      expect(node.label, contains('Payé'));
      expect(node.label, contains('À régler'));
    });
  });
}
