import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Factory responsable de la création des éléments de menu avec internationalisation
class MenuFactory {
  const MenuFactory._();

  /// Crée la liste complète des menus avec leurs sous-menus
  static List<MenuItem> createMenuItems(AppLocalizations l10n) {
    return [
      _createInscriptionsMenu(l10n),
      _createFinancesMenu(l10n),
      _createClassesMenu(l10n),
      _createDisciplinesMenu(l10n),
    ];
  }

  /// Menu Inscriptions avec ses sous-menus
  static MenuItem _createInscriptionsMenu(AppLocalizations l10n) {
    return MenuItem(
      id: MenuConstants.inscriptionsMenuId,
      title: l10n.menuInscriptions,
      icon: Icons.person_add_outlined,
      subMenus: [
        SubMenuItem(
          id: MenuConstants.inscriptionsDashboardId,
          title: l10n.subMenuDashboard,
          route: AppRoutesNames.inscriptionsDashboard,
        ),
        SubMenuItem(
          id: MenuConstants.premiereInscriptionId,
          title: l10n.subMenuFirstRegistration,
          route: AppRoutesNames.premiereInscription,
        ),
        SubMenuItem(
          id: MenuConstants.reInscriptionsId,
          title: l10n.subMenuReRegistrations,
          route: AppRoutesNames.reInscriptions,
        ),
        SubMenuItem(
          id: MenuConstants.preInscriptionsId,
          title: l10n.subMenuPreRegistrations,
          route: AppRoutesNames.preInscriptions,
        ),

      ],
    );
  }

  /// Menu Finances avec ses sous-menus
  static MenuItem _createFinancesMenu(AppLocalizations l10n) {
    return MenuItem(
      id: MenuConstants.financesMenuId,
      title: l10n.menuFinances,
      icon: Icons.account_balance_outlined,
      subMenus: [
        SubMenuItem(
          id: MenuConstants.financesDashboardId,
          title: l10n.subMenuDashboard,
          route: AppRoutesNames.financesDashboard,
        ),
        SubMenuItem(
          id: MenuConstants.facturationsId,
          title: l10n.subMenuBilling,
          route: AppRoutesNames.facturations,
        ),
      ],
    );
  }

  /// Menu Classes avec ses sous-menus
  static MenuItem _createClassesMenu(AppLocalizations l10n) {
    return MenuItem(
      id: MenuConstants.classesMenuId,
      title: l10n.menuClasses,
      icon: Icons.class_outlined,
      subMenus: [
        SubMenuItem(
          id: MenuConstants.classesDashboardId,
          title: l10n.subMenuDashboard,
          route: AppRoutesNames.classesDashboard,
        ),
        SubMenuItem(
          id: MenuConstants.organisationId,
          title: l10n.subMenuOrganization,
          route: AppRoutesNames.organisation,
        ),
        SubMenuItem(
          id: MenuConstants.classesListId,
          title: l10n.subMenuClassesList,
          route: AppRoutesNames.classesList,
        ),
      ],
    );
  }

  /// Menu Disciplines avec ses sous-menus
  static MenuItem _createDisciplinesMenu(AppLocalizations l10n) {
    return MenuItem(
      id: MenuConstants.disciplinesMenuId,
      title: l10n.menuDisciplines,
      icon: Icons.school_outlined,
      subMenus: [
        SubMenuItem(
          id: MenuConstants.disciplinesDashboardId,
          title: l10n.subMenuDashboard,
          route: AppRoutesNames.disciplinesDashboard,
        ),
        SubMenuItem(
          id: MenuConstants.presencesId,
          title: l10n.subMenuAttendance,
          route: AppRoutesNames.presences,
        ),
        SubMenuItem(
          id: MenuConstants.disciplinesListId,
          title: l10n.subMenuDisciplinesList,
          route: AppRoutesNames.disciplinesList,
        ),
      ],
    );
  }
}
