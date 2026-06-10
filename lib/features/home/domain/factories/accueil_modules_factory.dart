import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Construit les 4 cartes modules de la page d'accueil avec leur copy localisée,
/// leurs accents (spec §03) et leur mappage de navigation (spec §10).
///
/// Les libellés de puces réutilisent les titres de sous-menus existants pour
/// rester cohérents avec la sidebar (le `\n` de « Composition des classes » est
/// neutralisé). Les titres de cartes réutilisent les titres de menus.
class AccueilModulesFactory {
  const AccueilModulesFactory._();

  static List<AccueilModule> create(AppLocalizations l10n) {
    // Titre des tableaux de bord = libellé « Tableau de bord » partagé.
    final dashboardTitle = l10n.subMenuDashboard;

    return [
      AccueilModule(
        id: MenuConstants.inscriptionsMenuId,
        title: l10n.menuInscriptions,
        description: l10n.accueilModuleInscriptionsDescription,
        icon: Icons.person_add_alt_1_outlined,
        accent: AppColors.accueilInscriptionsAccent,
        softBackground: AppColors.accueilInscriptionsSoft,
        dashboardTarget: AccueilNavTarget(
          menuId: MenuConstants.inscriptionsMenuId,
          subMenuId: MenuConstants.inscriptionsDashboardId,
          title: dashboardTitle,
        ),
        quickLinks: [
          AccueilQuickLink(
            label: l10n.subMenuFirstRegistration,
            target: AccueilNavTarget(
              menuId: MenuConstants.inscriptionsMenuId,
              subMenuId: MenuConstants.premiereInscriptionId,
              title: l10n.subMenuFirstRegistration,
            ),
          ),
          AccueilQuickLink(
            label: l10n.subMenuReRegistrations,
            target: AccueilNavTarget(
              menuId: MenuConstants.inscriptionsMenuId,
              subMenuId: MenuConstants.reInscriptionsId,
              title: l10n.subMenuReRegistrations,
            ),
          ),
        ],
      ),
      AccueilModule(
        id: MenuConstants.financesMenuId,
        title: l10n.menuFinances,
        description: l10n.accueilModuleFinancesDescription,
        icon: Icons.account_balance_outlined,
        accent: AppColors.accueilFinancesAccent,
        softBackground: AppColors.accueilFinancesSoft,
        dashboardTarget: AccueilNavTarget(
          menuId: MenuConstants.financesMenuId,
          subMenuId: MenuConstants.financesDashboardId,
          title: dashboardTitle,
        ),
        quickLinks: [
          AccueilQuickLink(
            label: l10n.subMenuBilling,
            target: AccueilNavTarget(
              menuId: MenuConstants.financesMenuId,
              subMenuId: MenuConstants.facturationsId,
              title: l10n.subMenuBilling,
            ),
          ),
        ],
      ),
      AccueilModule(
        id: MenuConstants.classesMenuId,
        title: l10n.menuClasses,
        description: l10n.accueilModuleClassesDescription,
        icon: Icons.grid_view_outlined,
        accent: AppColors.accueilClassesAccent,
        softBackground: AppColors.accueilClassesSoft,
        dashboardTarget: AccueilNavTarget(
          menuId: MenuConstants.classesMenuId,
          subMenuId: MenuConstants.classesDashboardId,
          title: dashboardTitle,
        ),
        quickLinks: [
          AccueilQuickLink(
            label: l10n.subMenuOrganization.replaceAll('\n', ' '),
            target: AccueilNavTarget(
              menuId: MenuConstants.classesMenuId,
              subMenuId: MenuConstants.organisationId,
              title: l10n.subMenuOrganization,
            ),
          ),
          AccueilQuickLink(
            label: l10n.subMenuClassesList,
            target: AccueilNavTarget(
              menuId: MenuConstants.classesMenuId,
              subMenuId: MenuConstants.classesListId,
              title: l10n.subMenuClassesList,
            ),
          ),
        ],
      ),
      AccueilModule(
        id: MenuConstants.disciplinesMenuId,
        title: l10n.menuDisciplines,
        description: l10n.accueilModuleDisciplinesDescription,
        icon: Icons.school_outlined,
        accent: AppColors.accueilDisciplinesAccent,
        softBackground: AppColors.accueilDisciplinesSoft,
        dashboardTarget: AccueilNavTarget(
          menuId: MenuConstants.disciplinesMenuId,
          subMenuId: MenuConstants.disciplinesDashboardId,
          title: dashboardTitle,
        ),
        quickLinks: [
          AccueilQuickLink(
            label: l10n.subMenuAttendance,
            target: AccueilNavTarget(
              menuId: MenuConstants.disciplinesMenuId,
              subMenuId: MenuConstants.presencesId,
              title: l10n.subMenuAttendance,
            ),
          ),
          AccueilQuickLink(
            label: l10n.subMenuDisciplinesList,
            target: AccueilNavTarget(
              menuId: MenuConstants.disciplinesMenuId,
              subMenuId: MenuConstants.disciplinesListId,
              title: l10n.subMenuDisciplinesList,
            ),
          ),
        ],
      ),
    ];
  }
}
