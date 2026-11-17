import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';
import 'package:school_app_flutter/router/app_router.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// L'ancien menu Ressources humaines a été éclaté en RH · Personnel, RH ·
/// Présences et RH · Paie. Il n'est plus offert nulle part, et ses anciennes
/// adresses mènent à l'écran qui a repris chaque page.
void main() {
  final l10n = AppLocalizationsFr();
  final tousDroits = Perm.values.map((p) => p.wire).toList();

  test('ni la barre ni la grille ne proposent plus Ressources humaines', () {
    expect(
      MenuFactory.createMenuItems(
        l10n,
        permissions: tousDroits,
      ).map((menu) => menu.id),
      isNot(contains(MenuConstants.legacyHrMenuId)),
    );
    expect(
      AccueilModulesFactory.create(
        l10n,
        permissions: tousDroits,
      ).map((module) => module.id),
      isNot(contains(MenuConstants.legacyHrMenuId)),
    );
  });

  test('les trois modules RH suivent les Dépenses dans la barre', () {
    final ids = MenuFactory.createMenuItems(
      l10n,
      permissions: tousDroits,
    ).map((menu) => menu.id).toList();
    final depenses = ids.indexOf(MenuConstants.expenseMenuId);

    expect(ids.sublist(depenses + 1, depenses + 4), [
      MenuConstants.hrPersonnelMenuId,
      MenuConstants.hrPresenceMenuId,
      MenuConstants.hrPayrollMenuId,
    ]);
  });

  group('les anciennes adresses', () {
    /// Le `redirect` déclaré pour [path] — une ancienne adresse ne rend rien.
    String? redirectOf(String path) {
      final route = AppRouter.buildRoutes().whereType<GoRoute>().firstWhere(
        (route) => route.path == path,
      );
      expect(route.builder, isNull);
      expect(route.pageBuilder, isNull);
      return route.redirect!(_FakeContext(), _FakeState()) as String?;
    }

    test('chaque page de l ancien menu mène à son remplaçant', () {
      expect(
        redirectOf('/ressources-humaines/fichier-du-personnel'),
        AppRoutesNames.hrPersonnelFile,
      );
      expect(
        redirectOf('/ressources-humaines/pointage'),
        AppRoutesNames.hrPresenceRegister,
      );
      expect(redirectOf('/ressources-humaines/paie'), AppRoutesNames.hrPayroll);
      expect(
        redirectOf('/ressources-humaines/paie-arrieres'),
        AppRoutesNames.hrPayrollArrears,
      );
    });

    test(
      'dans la coquille, un ancien sous-menu mène à celui qui le reprend',
      () {
        String? shell(String location) =>
            AppRoutesNames.legacyHrShellRedirect(Uri.parse(location));

        expect(
          shell('/home/fichier-du-personnel'),
          '/home/${MenuConstants.hrPersonnelFileId}',
        );
        expect(
          shell('/home/pointage?jour=2026-11-17'),
          '/home/${MenuConstants.hrPresenceRegisterId}?jour=2026-11-17',
        );
        expect(
          shell('/home/fichier-du-personnel/agent-1'),
          '/home/${MenuConstants.hrPersonnelFileId}/agent-1',
        );
        expect(shell('/home/${MenuConstants.hrPersonnelFileId}'), isNull);
        expect(shell('/home'), isNull);
      },
    );
  });
}

class _FakeContext extends Fake implements BuildContext {}

class _FakeState extends Fake implements GoRouterState {}
