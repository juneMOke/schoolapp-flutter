import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les ressources humaines ont leur PROPRE menu : le fichier du personnel,
/// gardé par `hr.staff.read`, le Pointage, gardé par `hr.attendance.read`,
/// puis la Paie, gardée par `hr.pay.read`. Chaque sous-menu disparaît sans son
/// droit ; le menu entier, sans aucun des trois. Ces tests tiennent la place et les gardes.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('un menu propre : le fichier du personnel, le Pointage, la Paie', () {
    final menus = MenuFactory.createMenuItems(l10n, permissions: tousDroits);
    final rh = menus.firstWhere((menu) => menu.id == MenuConstants.hrMenuId);

    expect(rh.title, 'Ressources humaines');
    expect(rh.subMenus.map((sub) => sub.id), [
      MenuConstants.hrStaffFileId,
      MenuConstants.hrStaffAttendanceId,
      MenuConstants.hrPayrollId,
    ]);
    expect(rh.subMenus.first.title, 'Fichier du personnel');
    expect(rh.subMenus.first.route, AppRoutesNames.hrStaffFile);
    expect(rh.subMenus[1].title, 'Pointage & présences');
    expect(rh.subMenus[1].route, AppRoutesNames.hrStaffAttendance);
    expect(rh.subMenus.last.title, 'Paie');
    expect(rh.subMenus.last.route, AppRoutesNames.hrPayroll);
    expect(AppRoutesNames.hrPayroll, '/ressources-humaines/paie');
    expect(
      AppRoutesNames.hrStaffFile,
      '/ressources-humaines/fichier-du-personnel',
    );
    expect(AppRoutesNames.hrStaffAttendance, '/ressources-humaines/pointage');
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

  test('sans `hr.staff.read`, `hr.attendance.read` ni `hr.pay.read`, le menu '
      'ENTIER disparaît', () {
    final sansLecture = tousDroits
        .where(
          (wire) =>
              wire != Perm.hrStaffRead.wire &&
              wire != Perm.hrAttendanceRead.wire &&
              wire != Perm.hrPayRead.wire,
        )
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

  test('`hr.attendance.read` seul ouvre le Pointage, pas le fichier', () {
    final rh = MenuFactory.createMenuItems(
      l10n,
      permissions: [Perm.hrAttendanceRead.wire],
    ).firstWhere((menu) => menu.id == MenuConstants.hrMenuId);

    expect(rh.subMenus.map((sub) => sub.id), [
      MenuConstants.hrStaffAttendanceId,
    ]);
    final route = Uri.parse(AppRoutesNames.hrStaffAttendance);
    expect(canAccessLocation(route, [Perm.hrStaffRead.wire]), isFalse);
    expect(canAccessLocation(route, [Perm.hrAttendanceRead.wire]), isTrue);
  });

  test('`hr.pay.read` seul ouvre la Paie, et sa route', () {
    final rh = MenuFactory.createMenuItems(
      l10n,
      permissions: [Perm.hrPayRead.wire],
    ).firstWhere((menu) => menu.id == MenuConstants.hrMenuId);

    expect(rh.subMenus.map((sub) => sub.id), [MenuConstants.hrPayrollId]);
    final route = Uri.parse(AppRoutesNames.hrPayroll);
    expect(canAccessLocation(route, [Perm.hrStaffRead.wire]), isFalse);
    expect(canAccessLocation(route, [Perm.hrPayRead.wire]), isTrue);
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
      MenuConstants.hrStaffAttendanceId,
      MenuConstants.hrPayrollId,
    ]);
  });
}
