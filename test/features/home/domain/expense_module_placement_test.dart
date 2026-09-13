import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Les dépenses ont leur PROPRE menu : la source de fonds ne débite aucune
/// caisse en V1, et les ranger sous Finances laisserait croire le contraire.
/// Ces tests tiennent la place — ce qu'un refactor de navigation casse en
/// silence.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('un menu propre : le tableau de bord, puis le registre', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final depenses = menus.firstWhere(
      (menu) => menu.id == MenuConstants.expenseMenuId,
    );
    expect(depenses.subMenus.map((sub) => sub.id), [
      MenuConstants.expenseDashboardId,
      MenuConstants.expenseRegisterId,
    ]);
    expect(depenses.subMenus.last.title, 'Frais de fonctionnement');
  });

  test('Finances ne porte pas les dépenses', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final finances = menus.firstWhere(
      (menu) => menu.id == MenuConstants.financesMenuId,
    );
    expect(
      finances.subMenus.map((sub) => sub.id),
      isNot(contains(MenuConstants.expenseRegisterId)),
    );
  });

  test('la grille d’accueil suit la barre : une carte propre', () {
    final modules = AccueilModulesFactory.create(l10n, permissions: tousDroits);
    final depenses = modules.firstWhere(
      (module) => module.id == MenuConstants.expenseMenuId,
    );
    expect(depenses.subModules.map((sub) => sub.target.subMenuId), [
      MenuConstants.expenseDashboardId,
      MenuConstants.expenseRegisterId,
    ]);
  });

  test('sans `expense.read`, le menu ENTIER disparaît', () {
    final menus = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits
          .where((wire) => wire != Perm.expenseRead.wire)
          .toList(),
    );
    expect(
      menus.map((menu) => menu.id),
      isNot(contains(MenuConstants.expenseMenuId)),
    );
  });

  test('`expense.read` seul suffit à consulter les deux écrans', () {
    final menus = MenuFactory.createMenuItems(
      l10n,
      permissions: [Perm.expenseRead.wire],
    );
    final depenses = menus.firstWhere(
      (menu) => menu.id == MenuConstants.expenseMenuId,
    );
    expect(depenses.subMenus, hasLength(2));
  });
}
