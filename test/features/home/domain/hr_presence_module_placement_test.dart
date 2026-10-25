import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Présences est un module PROPRE, posé après RH · Personnel, sous
/// `hr.attendance.read`. L'onglet Pointage des Ressources humaines reste en
/// place à côté.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  List<String> menuIds(List<String> permissions) => MenuFactory.createMenuItems(
    l10n,
    permissions: permissions,
  ).map((menu) => menu.id).toList();

  test('un menu propre : tableau de bord, fiche, registre, récapitulatif', () {
    final module = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).firstWhere((menu) => menu.id == MenuConstants.hrPresenceMenuId);

    expect(module.title, 'RH · Présences');
    expect(module.subMenus.map((sub) => sub.id), [
      MenuConstants.hrPresenceDashboardId,
      MenuConstants.hrPresenceFicheId,
      MenuConstants.hrPresenceRegisterId,
      MenuConstants.hrPresenceRecapId,
    ]);
    expect(module.subMenus.map((sub) => sub.title), [
      'Tableau de bord',
      'Fiche individuelle',
      'Registre du jour',
      'Récapitulatif',
    ]);
    expect(
      AppRoutesNames.hrPresenceDashboard,
      '/rh-presences/rh-presences-tableau-de-bord',
    );
    expect(
      AppRoutesNames.hrPresenceRegister,
      '/rh-presences/rh-presences-registre',
    );
  });

  test('il suit RH · Personnel, et le Pointage reste en place', () {
    final ids = menuIds(tousDroits);
    expect(
      ids.indexOf(MenuConstants.hrPresenceMenuId),
      ids.indexOf(MenuConstants.hrPersonnelMenuId) + 1,
    );
    final hr = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).firstWhere((menu) => menu.id == MenuConstants.hrMenuId);
    expect(
      hr.subMenus.map((sub) => sub.id),
      contains(MenuConstants.hrStaffAttendanceId),
    );
  });

  test('`hr.attendance.read` suffit à ouvrir ses écrans et leurs routes', () {
    expect(
      menuIds([Perm.hrAttendanceRead.wire]),
      contains(MenuConstants.hrPresenceMenuId),
    );
    for (final route in [
      AppRoutesNames.hrPresenceDashboard,
      AppRoutesNames.hrPresenceFiche,
      AppRoutesNames.hrPresenceRegister,
      AppRoutesNames.hrPresenceRecap,
    ]) {
      expect(
        canAccessLocation(Uri.parse(route), [Perm.hrAttendanceRead.wire]),
        isTrue,
        reason: route,
      );
    }
    // L'économe lit les mois clos dans la Paie, pas le registre.
    expect(
      canAccessLocation(Uri.parse(AppRoutesNames.hrPresenceRegister), [
        Perm.hrPayRead.wire,
        Perm.hrStaffRead.wire,
      ]),
      isFalse,
    );
  });

  test('sans `hr.attendance.read`, le module disparaît du menu et de '
      'l\'accueil', () {
    final sansLecture = tousDroits
        .where((wire) => wire != Perm.hrAttendanceRead.wire)
        .toList();
    expect(
      menuIds(sansLecture),
      isNot(contains(MenuConstants.hrPresenceMenuId)),
    );
    expect(
      AccueilModulesFactory.create(
        l10n,
        permissions: sansLecture,
      ).map((module) => module.id),
      isNot(contains(MenuConstants.hrPresenceMenuId)),
    );
  });

  test("la grille d'accueil suit la barre : une carte propre", () {
    final module = AccueilModulesFactory.create(
      l10n,
      permissions: tousDroits,
    ).firstWhere((module) => module.id == MenuConstants.hrPresenceMenuId);
    expect(module.subModules.map((sub) => sub.target.subMenuId), [
      MenuConstants.hrPresenceDashboardId,
      MenuConstants.hrPresenceFicheId,
      MenuConstants.hrPresenceRegisterId,
      MenuConstants.hrPresenceRecapId,
    ]);
  });
}
