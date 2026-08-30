import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// La caisse est **étanche à la scolarité** (ADR-020, invariant I-4) : une vente
/// n'apparaît sur aucune note de perception et n'alimente aucun poste dû. La
/// ranger sous Finances laissait entendre le contraire — et l'y remettre serait
/// défaire la décision sans que rien ne le dise.
///
/// Ces tests tiennent la PLACE, pas le contenu : c'est ce qu'un refactor de
/// navigation peut casser en silence. Le harnais de `accueil_page_test`
/// n'accorde pas le droit de caisse, et ne voit donc jamais cette carte.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('la caisse a son PROPRE menu, avec Achats et Historiques', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final boutique = menus.firstWhere(
      (menu) => menu.id == MenuConstants.boutiqueMenuId,
    );

    expect(boutique.subMenus.map((sub) => sub.id), [
      MenuConstants.boutiqueAchatsId,
      MenuConstants.boutiqueHistoriqueId,
    ]);
  });

  test('Finances ne porte PLUS la boutique', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final finances = menus.firstWhere(
      (menu) => menu.id == MenuConstants.financesMenuId,
    );

    expect(
      finances.subMenus.map((sub) => sub.id),
      isNot(contains(MenuConstants.boutiqueAchatsId)),
    );
  });

  test('la grille d\'accueil suit la barre : une carte propre', () {
    // Les deux surfaces lisent le même registre ; c'est ce partage qui les
    // empêche de diverger, et ce test le constate là où l'œil le verrait.
    final modules = AccueilModulesFactory.create(l10n, permissions: tousDroits);
    final boutique = modules.firstWhere(
      (module) => module.id == MenuConstants.boutiqueMenuId,
    );

    expect(boutique.subModules.map((sub) => sub.target.subMenuId), [
      MenuConstants.boutiqueAchatsId,
      MenuConstants.boutiqueHistoriqueId,
    ]);
    final finances = modules.firstWhere(
      (module) => module.id == MenuConstants.financesMenuId,
    );
    expect(
      finances.subModules.map((sub) => sub.target.subMenuId),
      isNot(contains(MenuConstants.boutiqueAchatsId)),
    );
  });

  test('sans droit de caisse, le menu ENTIER disparaît', () {
    // Un menu qui s'ouvre sur le vide invite à cliquer pour rien.
    final menus = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits
          .where((wire) => wire != Perm.boutiqueSaleRead.wire)
          .toList(),
    );

    expect(
      menus.map((menu) => menu.id),
      isNot(contains(MenuConstants.boutiqueMenuId)),
    );
  });
}
