import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_navigation_helper.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Sortie du wizard d'inscription : le retour au listing doit être RÉEL, quel
/// que soit le chemin d'ouverture (`push` depuis une ligne de listing, `go`
/// depuis le bouton de création).
void main() {
  late BuildContext wizardContext;
  late int homeMountCount;
  late String? homeSubMenuId;

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    homeMountCount = 0;
    homeSubMenuId = null;

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          name: AppRoutesNames.home,
          builder: (context, state) => _Home(
            subMenuId: state.uri.queryParameters['subMenuId'],
            onMount: (subMenuId) {
              homeMountCount++;
              homeSubMenuId = subMenuId;
            },
          ),
        ),
        // Le wizard vit sous une ShellRoute, comme en production : `canPop()`
        // doit rester capable de distinguer les deux piles.
        ShellRoute(
          builder: (context, state, child) => child,
          routes: [
            GoRoute(
              path: '/enrollments/detail/new',
              builder: (context, state) => Builder(
                builder: (context) {
                  wizardContext = context;
                  return const Scaffold(body: Text('WIZARD'));
                },
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'wizard ouvert en PUSH (reprise d\'un brouillon depuis le listing) → '
    'dépile réellement vers le listing',
    (tester) async {
      final router = await pumpRouter(tester);
      // Le listing pousse le wizard et rafraîchit sa liste au retour : c'est
      // l'achèvement de CETTE attente qui rend la main au listing.
      var listingRegainedControl = false;
      router
          .push('/enrollments/detail/new')
          .then((_) => listingRegainedControl = true);
      await tester.pumpAndSettle();
      expect(find.text('WIZARD'), findsOneWidget);

      EnrollmentNavigationHelper.leaveWizardToListing(wizardContext);
      await tester.pumpAndSettle();

      expect(find.text('WIZARD'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      // Discriminant : un `goNamed` retirerait aussi le wizard de l'écran,
      // mais SANS jamais achever l'attente — le listing ne se rafraîchirait
      // pas et garderait son état d'avant le wizard.
      expect(listingRegainedControl, isTrue);
    },
  );

  testWidgets(
    'wizard ouvert en GO (bouton de création) → redirige vers l\'accueil avec '
    'le sous-menu Première inscription',
    (tester) async {
      final router = await pumpRouter(tester);
      router.go('/enrollments/detail/new');
      await tester.pumpAndSettle();
      expect(find.text('WIZARD'), findsOneWidget);

      EnrollmentNavigationHelper.leaveWizardToListing(wizardContext);
      await tester.pumpAndSettle();

      expect(find.text('WIZARD'), findsNothing);
      expect(homeSubMenuId, MenuConstants.premiereInscriptionId);
    },
  );

  testWidgets(
    'RACINE DU BUG : avec l\'accueil sous la pile, `goNamed(home)` ne remonte '
    'PAS la page — la clé de page GoRouter vaut le chemin matché, sans les '
    'query params (d\'où le dépilage ci-dessus)',
    (tester) async {
      final router = await pumpRouter(tester);
      expect(homeMountCount, 1);
      expect(homeSubMenuId, isNull);

      router.push('/enrollments/detail/new');
      await tester.pumpAndSettle();

      EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(
        wizardContext,
      );
      await tester.pumpAndSettle();

      // La page d'accueil existante est réutilisée telle quelle : aucun
      // remontage, `subMenuId` ignoré — et donc, en production, aucun
      // rechargement du listing (dossier finalisé encore badgé « Brouillon »).
      expect(homeMountCount, 1);
      expect(homeSubMenuId, isNull);
    },
  );
}

class _Home extends StatefulWidget {
  final String? subMenuId;
  final void Function(String? subMenuId) onMount;

  const _Home({required this.subMenuId, required this.onMount});

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
    widget.onMount(widget.subMenuId);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('HOME'));
}
