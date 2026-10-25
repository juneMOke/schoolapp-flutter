import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Paie est un module PROPRE (spec « R.H. ▸ Paie », carte des
/// sous-modules), posé après RH · Présences, tout entier sous `hr.pay.read`.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();
  const sousModules = [
    MenuConstants.hrPayrollId,
    MenuConstants.hrPayrollAdvancesId,
    MenuConstants.hrPayrollArrearsId,
    MenuConstants.hrPayrollSettingsId,
  ];
  const routes = [
    AppRoutesNames.hrPayroll,
    AppRoutesNames.hrPayrollAdvances,
    AppRoutesNames.hrPayrollArrears,
    AppRoutesNames.hrPayrollSettings,
  ];

  List<String> menuIds(List<String> permissions) => MenuFactory.createMenuItems(
    l10n,
    permissions: permissions,
  ).map((menu) => menu.id).toList();

  test('un menu propre : paie, avances et prêts, arriérés, configuration', () {
    final module = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).firstWhere((menu) => menu.id == MenuConstants.hrPayrollMenuId);

    expect(module.title, 'RH · Paie');
    expect(module.subMenus.map((sub) => sub.id), sousModules);
    expect(module.subMenus.map((sub) => sub.title), [
      'Paie',
      'Avances & prêts',
      'Arriérés de salaire',
      'Configuration',
    ]);
    expect(module.subMenus.map((sub) => sub.route), routes);
    expect(AppRoutesNames.hrPayroll, '/rh-paie/paie');
    expect(AppRoutesNames.hrPayrollSettings, '/rh-paie/paie-configuration');
  });

  test('il suit RH · Présences', () {
    final ids = menuIds(tousDroits);
    expect(
      ids.indexOf(MenuConstants.hrPayrollMenuId),
      ids.indexOf(MenuConstants.hrPresenceMenuId) + 1,
    );
  });

  test('`hr.pay.read` suffit à ouvrir ses écrans et leurs routes — le barème '
      'compris, que l économe consulte', () {
    expect(
      menuIds([Perm.hrPayRead.wire]),
      contains(MenuConstants.hrPayrollMenuId),
    );
    for (final route in routes) {
      expect(
        canAccessLocation(Uri.parse(route), [Perm.hrPayRead.wire]),
        isTrue,
        reason: route,
      );
      expect(
        canAccessLocation(Uri.parse(route), [
          Perm.hrStaffRead.wire,
          Perm.hrAttendanceRead.wire,
        ]),
        isFalse,
        reason: route,
      );
    }
  });

  test('sans `hr.pay.read`, le module disparaît du menu et de l accueil', () {
    final sansLecture = tousDroits
        .where((wire) => wire != Perm.hrPayRead.wire)
        .toList();
    expect(
      menuIds(sansLecture),
      isNot(contains(MenuConstants.hrPayrollMenuId)),
    );
    expect(
      AccueilModulesFactory.create(
        l10n,
        permissions: sansLecture,
      ).map((module) => module.id),
      isNot(contains(MenuConstants.hrPayrollMenuId)),
    );
  });

  test("la grille d'accueil suit la barre : une carte propre", () {
    final module = AccueilModulesFactory.create(
      l10n,
      permissions: tousDroits,
    ).firstWhere((module) => module.id == MenuConstants.hrPayrollMenuId);
    expect(module.subModules.map((sub) => sub.target.subMenuId), sousModules);
  });
}
