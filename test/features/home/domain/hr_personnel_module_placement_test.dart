import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Personnel est un module PROPRE, posé après les Ressources humaines
/// qu'il laisse intactes : son tableau de bord, puis son fichier, tous deux
/// sous `hr.staff.read`.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('un menu propre : tableau de bord, puis fichier', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final module = menus.firstWhere(
      (menu) => menu.id == MenuConstants.hrPersonnelMenuId,
    );

    expect(module.title, 'RH · Personnel');
    expect(module.subMenus.map((sub) => sub.id), [
      MenuConstants.hrPersonnelDashboardId,
      MenuConstants.hrPersonnelFileId,
    ]);
    expect(module.subMenus.first.title, 'Tableau de bord');
    expect(module.subMenus.last.title, 'Fichier du personnel');
    expect(
      AppRoutesNames.hrPersonnelDashboard,
      '/rh-personnel/rh-personnel-tableau-de-bord',
    );
    expect(
      AppRoutesNames.hrPersonnelFile,
      '/rh-personnel/rh-personnel-fichier',
    );
  });

  test('il suit les Ressources humaines, qui restent en place', () {
    final ids = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).map((menu) => menu.id).toList();

    expect(
      ids.indexOf(MenuConstants.hrPersonnelMenuId),
      ids.indexOf(MenuConstants.hrMenuId) + 1,
    );
  });

  test('`hr.staff.read` ouvre les deux écrans et leurs routes', () {
    final module = MenuFactory.createMenuItems(
      l10n,
      permissions: [Perm.hrStaffRead.wire],
    ).firstWhere((menu) => menu.id == MenuConstants.hrPersonnelMenuId);

    expect(module.subMenus, hasLength(2));
    for (final route in [
      AppRoutesNames.hrPersonnelDashboard,
      AppRoutesNames.hrPersonnelFile,
    ]) {
      expect(
        canAccessLocation(Uri.parse(route), [Perm.hrStaffRead.wire]),
        isTrue,
      );
      expect(
        canAccessLocation(Uri.parse(route), [Perm.hrPayRead.wire]),
        isFalse,
      );
    }
  });

  test(
    'sans `hr.staff.read`, le module disparaît du menu et de l\'accueil',
    () {
      final sansLecture = tousDroits
          .where((wire) => wire != Perm.hrStaffRead.wire)
          .toList();

      expect(
        MenuFactory.createMenuItems(
          l10n,
          permissions: sansLecture,
        ).map((menu) => menu.id),
        isNot(contains(MenuConstants.hrPersonnelMenuId)),
      );
      expect(
        AccueilModulesFactory.create(
          l10n,
          permissions: sansLecture,
        ).map((module) => module.id),
        isNot(contains(MenuConstants.hrPersonnelMenuId)),
      );
    },
  );

  test("la grille d'accueil suit la barre : une carte propre", () {
    final module = AccueilModulesFactory.create(
      l10n,
      permissions: tousDroits,
    ).firstWhere((module) => module.id == MenuConstants.hrPersonnelMenuId);

    expect(module.subModules.map((sub) => sub.target.subMenuId), [
      MenuConstants.hrPersonnelDashboardId,
      MenuConstants.hrPersonnelFileId,
    ]);
  });
}
