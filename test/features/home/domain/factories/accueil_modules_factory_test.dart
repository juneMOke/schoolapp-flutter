import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// La grille d'accueil traite tous les tableaux de bord de la même façon : la
/// ligne est mise en avant, et la carte s'ouvre dessus.
void main() {
  final l10n = AppLocalizationsFr();
  final modules = AccueilModulesFactory.create(
    l10n,
    permissions: Perm.values.map((p) => p.wire).toList(),
  );

  test('toute ligne « Tableau de bord » est mise en avant', () {
    final plain = [
      for (final module in modules)
        for (final sub in module.subModules)
          if (sub.label == l10n.subMenuDashboard && !sub.isDashboard)
            '${module.id} ▸ ${sub.target.subMenuId}',
    ];

    expect(plain, isEmpty);
  });

  test('Trésorerie et les trois modules RH déclarent leur tableau de bord', () {
    const dashboards = {
      MenuConstants.treasuryMenuId: MenuConstants.treasuryDashboardId,
      MenuConstants.hrPersonnelMenuId: MenuConstants.hrPersonnelDashboardId,
      MenuConstants.hrPresenceMenuId: MenuConstants.hrPresenceDashboardId,
      MenuConstants.hrPayrollMenuId: MenuConstants.hrPayrollDashboardId,
    };

    for (final MapEntry(key: menuId, value: dashboardId)
        in dashboards.entries) {
      final module = modules.firstWhere((module) => module.id == menuId);
      expect(
        module.subModules
            .where((sub) => sub.isDashboard)
            .map((sub) => sub.target.subMenuId),
        [dashboardId],
        reason: menuId,
      );
      expect(module.entry.target.subMenuId, dashboardId, reason: menuId);
    }
  });
}
