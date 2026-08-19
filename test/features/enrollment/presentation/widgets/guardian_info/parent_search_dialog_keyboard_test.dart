import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSearchParentsUseCase extends Mock implements SearchParentsUseCase {}

/// `Dialog` retire la hauteur du clavier (`viewInsets`) à ce qu'il offre à son
/// contenu. En paysage il ne reste qu'une centaine de dp, quand l'en-tête et le
/// formulaire de critères figés en coûtent trois fois plus : la modale
/// débordait dès que le clavier s'ouvrait sur un de ses quatre champs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSearchParentsUseCase searchUseCase;

  setUp(() {
    searchUseCase = _MockSearchParentsUseCase();
    when(
      () => searchUseCase(
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        surname: any(named: 'surname'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    ).thenAnswer((_) async => const Right(<LocalParent>[]));

    getIt.registerFactory<ParentSearchBloc>(
      () => ParentSearchBloc(search: searchUseCase),
    );
  });

  tearDown(() async => getIt.reset());

  Future<void> openDialogAt(WidgetTester tester, Size surface) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showParentSearchDialog(context: context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('paysage, clavier ouvert : la modale ne déborde plus', (
    tester,
  ) async {
    // 187 dp de haut moins les 2 × 24 dp d'inset ≈ les 139 dp qui restent à la
    // modale sur un téléphone en paysage clavier ouvert.
    await openDialogAt(tester, const Size(961.5, 187));

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'les critères doivent rejoindre le défilement, pas déborder',
    );
    // Les champs restent atteignables — en défilant, pas en débordant.
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Les deux tests ci-dessus mesurent deux dispositions STATIQUES, chacune à sa
  // taille de surface. La panne, elle, est dans la TRANSITION — et c'est
  // pourquoi ils sont restés verts alors que le champ était intapable.
  //
  // Le clavier ne redimensionne pas la surface : il pose des `viewInsets`, que
  // `Dialog` ajoute à son `insetPadding`. La hauteur offerte passe sous le
  // seuil, les critères rejoignent le défilement — et, sans identité stable, le
  // sous-arbre du formulaire est DÉTRUIT au passage. Chaque `EteeloTextInput`
  // dispose alors le `FocusNode` qu'il s'est créé : le focus meurt, le clavier
  // se referme, la hauteur revient, la bascule repart en sens inverse.
  // ─────────────────────────────────────────────────────────────────────────

  /// Le clavier tel que le framework le voit : des `viewInsets`, en pixels
  /// **physiques** (`MediaQuery` les divise par le `devicePixelRatio`).
  void ouvrirLeClavier(WidgetTester tester, {double dp = 300}) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: dp * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
  }

  /// Le champ « Prénom », désigné par son libellé et non par son rang : un
  /// cinquième critère ajouté au formulaire ne doit pas déplacer ce test en
  /// silence.
  Finder champPrenom() => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == 'Prénom',
    ),
    matching: find.byType(TextField),
  );

  Finder dansLeDefilement(Finder champ) =>
      find.ancestor(of: champ, matching: find.byType(SingleChildScrollView));

  testWidgets('le clavier qui s\'ouvre DÉPLACE les critères au lieu de les '
      'détruire : le champ garde son focus', (tester) async {
    await openDialogAt(tester, const Size(800, 600));

    final prenom = champPrenom();
    expect(prenom, findsOneWidget);
    expect(
      dansLeDefilement(prenom),
      findsNothing,
      reason: 'au départ, les critères sont figés hors du défilement',
    );

    await tester.tap(prenom);
    await tester.pump();
    final noeud = tester.widget<TextField>(prenom).focusNode;
    expect(noeud, isNotNull);
    expect(tester.binding.focusManager.primaryFocus, same(noeud));

    // Le geste qui déclenchait la panne : le clavier s'ouvre SUR ce champ.
    ouvrirLeClavier(tester);
    await tester.pump();
    // `Dialog` anime son `insetPadding` : la bascule tombe pendant l'animation.
    await tester.pump(const Duration(milliseconds: 300));

    // 1. La bascule a bien eu lieu. Sans cette assertion le test serait VIDE :
    //    un seuil mal simulé le laisserait vert sans que rien ne bouge.
    expect(
      dansLeDefilement(prenom),
      findsOneWidget,
      reason: 'sous le seuil, les critères doivent rejoindre le défilement',
    );

    // 2. Et le formulaire a été DÉPLACÉ, pas reconstruit — c'est tout l'objet
    //    de la clé. Un nœud neuf ici, c'est un champ qui a perdu son focus au
    //    moment précis où l'utilisateur allait taper dedans.
    expect(
      tester.widget<TextField>(prenom).focusNode,
      same(noeud),
      reason: 'le champ ne doit pas être reconstruit par la bascule',
    );
    expect(
      tester.binding.focusManager.primaryFocus,
      same(noeud),
      reason:
          'focus perdu = clavier refermé = bascule en sens inverse, en '
          'boucle : le champ devient intapable',
    );
  });

  testWidgets('et au retour : le clavier se referme, les critères reprennent '
      'leur place figée, toujours sans destruction', (tester) async {
    // Le sens inverse emprunte un autre chemin de réconciliation — l'élément
    // porteur de la clé est encore ACTIF quand sa nouvelle position l'inflate,
    // là où l'aller le trouvait déjà désactivé. Les deux méritent leur test.
    await openDialogAt(tester, const Size(800, 600));

    final prenom = champPrenom();
    await tester.tap(prenom);
    await tester.pump();
    final noeud = tester.widget<TextField>(prenom).focusNode;

    ouvrirLeClavier(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(dansLeDefilement(prenom), findsOneWidget);

    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      dansLeDefilement(prenom),
      findsNothing,
      reason: 'la hauteur revenue, les critères reprennent leur place figée',
    );
    expect(tester.widget<TextField>(prenom).focusNode, same(noeud));
    expect(tester.binding.focusManager.primaryFocus, same(noeud));
  });

  testWidgets('hauteur confortable : les critères restent figés en tête', (
    tester,
  ) async {
    await openDialogAt(tester, const Size(961.5, 900));

    expect(tester.takeException(), isNull);
    // Disposition d'origine : formulaire hors du défilement des résultats.
    final scrollable = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollable, findsOneWidget);
    expect(
      find.descendant(of: scrollable, matching: find.text('Rechercher')),
      findsNothing,
      reason: 'le bouton Rechercher appartient au bloc figé, pas au défilement',
    );
  });
  // ───────────────────────────────────────────────────────────────────────────
  // Débordements mesurés AVANT la reprise de la bascule, et que ces tailles
  // gardent fermés :
  //   • 411×731 et 360×640, SANS clavier  → 91 dp. Le `Wrap` des quatre
  //     critères passe à une colonne sous 460 dp de large : figé, le formulaire
  //     est plus haut que la modale. La hauteur seule ne pouvait pas l'éviter —
  //     c'est la largeur qui commande la hauteur du formulaire.
  //   • 640×360 et 731×411, clavier ouvert → 85 et 34 dp. Il ne restait que
  //     ~63 dp à la modale : l'en-tête débordait à lui tout seul, quelle que
  //     soit la place faite aux critères.
  // ───────────────────────────────────────────────────────────────────────────
  for (final surface in const [
    Size(360, 640), // téléphone portrait étroit
    Size(411, 731), // téléphone portrait
    Size(640, 360), // téléphone paysage
    Size(731, 411), // téléphone paysage
    Size(800, 600), // petite tablette
    Size(1280, 800), // tablette paysage (cible du projet)
  ]) {
    for (final clavier in const [false, true]) {
      testWidgets(
        '$surface, clavier ${clavier ? "ouvert" : "fermé"} : rien ne déborde',
        (tester) async {
          if (clavier) ouvrirLeClavier(tester);
          await openDialogAt(tester, surface);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
