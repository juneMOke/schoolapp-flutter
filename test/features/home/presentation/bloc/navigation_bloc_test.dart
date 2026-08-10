import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tous les droits déclarés : les tests de navigation portent sur l'accordéon
/// et la sélection, pas sur le filtrage (couvert par
/// `module_access_registry_test.dart`). Sans eux, l'arborescence serait vide et
/// ces tests ne diraient plus rien.
const _tousDroits = <String>[
  'enrollment.read',
  'enrollment.write',
  'enrollment.stats.read',
  'finance.charge.read',
  'finance.payment.read',
  'finance.stats.read',
  'classroom.read',
  'classroom.stats.read',
  'attendance.read',
  'attendance.stats.read',
  'discipline.read',
  'academics.course.read',
  'academics.result.read',
  'schedule.read',
  'editique.read',
  'editique.write',
];

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  bool anySubMenuActive(NavigationState state) =>
      state.menuItems.any((menu) => menu.subMenus.any((sub) => sub.isActive));

  group('NavigationState.initial', () {
    test('atterrit sur l\'Accueil, item feuille actif et seul surligné', () {
      final state = NavigationBloc(l10n, permissions: _tousDroits).state;

      expect(state.selectedMenuId, MenuConstants.accueilId);
      expect(state.selectedSubMenuId, MenuConstants.accueilId);
      expect(state.openedMenuId, MenuConstants.accueilId);
      expect(state.currentTitle, l10n.home);

      final accueil = state.menuItems.firstWhere(
        (menu) => menu.id == MenuConstants.accueilId,
      );
      expect(accueil.isLeaf, isTrue);
      expect(accueil.isActive, isTrue);

      final othersActive = state.menuItems
          .where((menu) => menu.id != MenuConstants.accueilId)
          .where((menu) => menu.isActive);
      expect(othersActive, isEmpty);
    });
  });

  group('Item feuille « Accueil »', () {
    blocTest<NavigationBloc, NavigationState>(
      'tap feuille après un sous-menu : revient à l\'Accueil sans sous-menu actif',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc
        ..add(
          SubMenuItemSelected(
            menuId: MenuConstants.inscriptionsMenuId,
            subMenuId: MenuConstants.premiereInscriptionId,
            title: l10n.subMenuFirstRegistration,
          ),
        )
        ..add(
          SubMenuItemSelected(
            menuId: MenuConstants.accueilId,
            subMenuId: MenuConstants.accueilId,
            title: l10n.home,
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.selectedSubMenuId, MenuConstants.accueilId);
        expect(bloc.state.currentTitle, l10n.home);
        // Aucun sous-menu d'aucun module ne doit rester surligné.
        expect(anySubMenuActive(bloc.state), isFalse);
      },
    );
  });

  group('Accordéon de module = divulgation, pas navigation', () {
    blocTest<NavigationBloc, NavigationState>(
      'ouvrir un module depuis l\'Accueil ne change pas l\'écran affiché',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) =>
          bloc.add(const MenuItemSelected(MenuConstants.inscriptionsMenuId)),
      verify: (bloc) {
        expect(bloc.state.openedMenuId, MenuConstants.inscriptionsMenuId);
        // L'écran reste l'Accueil tant qu'aucun sous-menu n'est choisi.
        expect(bloc.state.selectedSubMenuId, MenuConstants.accueilId);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'replier un module depuis l\'Accueil conserve l\'écran (pas de cul-de-sac)',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc
        ..add(const MenuItemSelected(MenuConstants.inscriptionsMenuId))
        ..add(const MenuItemSelected(MenuConstants.inscriptionsMenuId)),
      verify: (bloc) {
        expect(bloc.state.openedMenuId, isNull);
        // selectedSubMenuId NE doit PAS retomber à null (sinon placeholder).
        expect(bloc.state.selectedSubMenuId, MenuConstants.accueilId);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'replier un module en consultant une page conserve la page courante',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc
        ..add(
          SubMenuItemSelected(
            menuId: MenuConstants.financesMenuId,
            subMenuId: MenuConstants.facturationsId,
            title: l10n.subMenuBilling,
          ),
        )
        ..add(const MenuItemSelected(MenuConstants.financesMenuId)),
      verify: (bloc) {
        expect(bloc.state.openedMenuId, isNull);
        expect(bloc.state.selectedSubMenuId, MenuConstants.facturationsId);
      },
    );
  });

  // ADR-014 §5 — le refresh redescend un nouvel ensemble de droits en arrière-
  // plan. Sans reconstruction, le menu resterait celui du login : un droit
  // retiré continuerait d'offrir sa porte jusqu'au prochain démarrage.
  group('NavigationPermissionsChanged', () {
    blocTest<NavigationBloc, NavigationState>(
      'un droit retiré fait disparaître son menu',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc.add(
        NavigationPermissionsChanged(
          l10n: l10n,
          permissions: const ['classroom.read'],
        ),
      ),
      verify: (bloc) {
        final ids = bloc.state.menuItems.map((m) => m.id).toSet();
        expect(ids, contains(MenuConstants.classesMenuId));
        expect(ids, isNot(contains(MenuConstants.financesMenuId)));
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'la page affichée survit si elle reste accessible',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc
        ..add(
          SubMenuItemSelected(
            menuId: MenuConstants.classesMenuId,
            subMenuId: MenuConstants.organisationId,
            title: l10n.subMenuOrganization,
          ),
        )
        ..add(
          NavigationPermissionsChanged(
            l10n: l10n,
            permissions: const ['classroom.read'],
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.selectedSubMenuId, MenuConstants.organisationId);
        expect(bloc.state.currentTitle, l10n.subMenuOrganization);
      },
    );

    // Le cas qui compte : l'agent est SUR l'écran dont on vient de lui retirer
    // le droit. Le laisser là afficherait un écran qu'il ne peut plus ouvrir.
    blocTest<NavigationBloc, NavigationState>(
      'la page affichée devenue interdite renvoie à l\'accueil',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc
        ..add(
          SubMenuItemSelected(
            menuId: MenuConstants.financesMenuId,
            subMenuId: MenuConstants.facturationsId,
            title: l10n.subMenuBilling,
          ),
        )
        ..add(
          NavigationPermissionsChanged(
            l10n: l10n,
            permissions: const ['classroom.read'],
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.selectedSubMenuId, MenuConstants.accueilId);
        expect(bloc.state.selectedMenuId, MenuConstants.accueilId);
        expect(bloc.state.currentTitle, l10n.home);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'plus aucun droit : il ne reste que l\'accueil',
      build: () => NavigationBloc(l10n, permissions: _tousDroits),
      act: (bloc) => bloc.add(
        NavigationPermissionsChanged(l10n: l10n, permissions: const []),
      ),
      verify: (bloc) => expect(bloc.state.menuItems.map((m) => m.id), [
        MenuConstants.accueilId,
      ]),
    );
  });
}
