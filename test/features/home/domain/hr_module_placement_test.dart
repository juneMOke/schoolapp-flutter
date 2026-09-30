import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les ressources humaines ont leur PROPRE menu, câblé avant l'écran et gardé
/// par `hr.staff.read` : tant que le serveur ne sème pas ce droit, personne ne
/// le voit. Ces tests tiennent la place et la garde.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('un menu propre, qui ouvre le fichier du personnel', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final rh = menus.firstWhere((menu) => menu.id == MenuConstants.hrMenuId);

    expect(rh.title, 'Ressources humaines');
    expect(rh.subMenus.map((sub) => sub.id), [MenuConstants.hrStaffFileId]);
    expect(rh.subMenus.single.title, 'Fichier du personnel');
    expect(rh.subMenus.single.route, AppRoutesNames.hrStaffFile);
    expect(
      AppRoutesNames.hrStaffFile,
      '/ressources-humaines/fichier-du-personnel',
    );
  });

  test('il suit les Dépenses dans la barre', () {
    final ids = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).map((menu) => menu.id).toList();

    expect(
      ids.indexOf(MenuConstants.hrMenuId),
      ids.indexOf(MenuConstants.expenseMenuId) + 1,
    );
  });

  test('sans `hr.staff.read`, le menu ENTIER disparaît', () {
    final sansLecture = tousDroits
        .where((wire) => wire != Perm.hrStaffRead.wire)
        .toList();

    expect(
      MenuFactory.createMenuItems(
        l10n,
        permissions: sansLecture,
      ).map((menu) => menu.id),
      isNot(contains(MenuConstants.hrMenuId)),
    );
    expect(
      AccueilModulesFactory.create(
        l10n,
        permissions: sansLecture,
      ).map((module) => module.id),
      isNot(contains(MenuConstants.hrMenuId)),
    );
  });

  test('`hr.staff.read` seul suffit à ouvrir le fichier', () {
    final menus = MenuFactory.createMenuItems(
      l10n,
      permissions: [Perm.hrStaffRead.wire],
    );

    expect(menus.map((menu) => menu.id), contains(MenuConstants.hrMenuId));
  });

  test('la route refuse qui ne lit pas le fichier', () {
    final route = Uri.parse(AppRoutesNames.hrStaffFile);

    expect(canAccessLocation(route, const <String>[]), isFalse);
    expect(canAccessLocation(route, [Perm.hrPayRead.wire]), isFalse);
    expect(canAccessLocation(route, [Perm.hrStaffRead.wire]), isTrue);
  });

  test("la grille d'accueil suit la barre : une carte propre", () {
    final modules = AccueilModulesFactory.create(l10n, permissions: tousDroits);
    final rh = modules.firstWhere(
      (module) => module.id == MenuConstants.hrMenuId,
    );

    expect(rh.subModules.map((sub) => sub.target.subMenuId), [
      MenuConstants.hrStaffFileId,
    ]);
  });
}
