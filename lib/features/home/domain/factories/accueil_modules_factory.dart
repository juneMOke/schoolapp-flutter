import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Construit les cartes modules de la page d'accueil avec leur copy localisée,
/// leurs accents (spec §03) et leur mappage de navigation (spec §11).
///
/// Les libellés de sous-modules réutilisent les titres de sous-menus existants
/// pour rester cohérents avec la sidebar (le `\n` de « Composition des classes »
/// est neutralisé). Les titres de cartes réutilisent les titres de menus.
///
/// Plusieurs modules n'ont pas de tableau de bord (Cours, Résultats, Boutique,
/// Configuration) : leur page d'entrée est simplement leur premier sous-module
/// (cf. `AccueilModule.entry`).
class AccueilModulesFactory {
  const AccueilModulesFactory._();

  /// [permissions] filtre la grille (ADR-014) : une ligne de sous-module
  /// inaccessible disparaît, et une carte dont plus aucune ligne ne subsiste
  /// disparaît avec elle — une carte vide serait une porte sur rien.
  ///
  /// Les exigences viennent de `kModuleAccessRegistry`, partagé avec la barre
  /// latérale : les deux surfaces montrent donc exactement le même périmètre.
  /// `isSubMenuOffered` y ajoute les écrans retirés par décision produit
  /// (`kHiddenSubMenus`), lus depuis la même source pour la même raison.
  static List<AccueilModule> create(
    AppLocalizations l10n, {
    required List<String>? permissions,
  }) {
    final all = [
      _inscriptions(l10n),
      _finances(l10n),
      _feeControl(l10n),
      _boutique(l10n),
      _classes(l10n),
      _cours(l10n),
      _resultats(l10n),
      _disciplines(l10n),
      _configuration(l10n),
    ];

    final visible = <AccueilModule>[];
    for (final module in all) {
      final subModules = module.subModules
          .where((sub) => isSubMenuOffered(sub.target.subMenuId, permissions))
          .toList(growable: false);
      if (subModules.isEmpty) continue;
      visible.add(module.copyWith(subModules: subModules));
    }
    return visible;
  }

  /// Sous-module « Tableau de bord » — libellé partagé avec la sidebar.
  static AccueilSubModule _dashboard(
    AppLocalizations l10n, {
    required String menuId,
    required String subMenuId,
  }) {
    return AccueilSubModule(
      label: l10n.subMenuDashboard,
      isDashboard: true,
      target: AccueilNavTarget(
        menuId: menuId,
        subMenuId: subMenuId,
        title: l10n.subMenuDashboard,
      ),
    );
  }

  /// Sous-module ordinaire. [label] permet de neutraliser un retour à la ligne
  /// présent dans le libellé de sidebar sans perdre le titre d'origine, qui
  /// reste celui affiché par la barre supérieure une fois la page ouverte.
  static AccueilSubModule _page({
    required String menuId,
    required String subMenuId,
    required String title,
    String? label,
  }) {
    return AccueilSubModule(
      label: label ?? title,
      target: AccueilNavTarget(
        menuId: menuId,
        subMenuId: subMenuId,
        title: title,
      ),
    );
  }

  static AccueilModule _inscriptions(AppLocalizations l10n) {
    const menuId = MenuConstants.inscriptionsMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuInscriptions,
      description: l10n.accueilModuleInscriptionsDescription,
      icon: Icons.person_add_alt_1_outlined,
      accent: AppColors.accueilInscriptionsAccent,
      softBackground: AppColors.accueilInscriptionsSoft,
      subModules: [
        _dashboard(
          l10n,
          menuId: menuId,
          subMenuId: MenuConstants.inscriptionsDashboardId,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.premiereInscriptionId,
          title: l10n.subMenuFirstRegistration,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.reInscriptionsId,
          title: l10n.subMenuReRegistrations,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.preInscriptionsId,
          title: l10n.subMenuPreRegistrations,
        ),
      ],
    );
  }

  static AccueilModule _finances(AppLocalizations l10n) {
    const menuId = MenuConstants.financesMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuFinances,
      description: l10n.accueilModuleFinancesDescription,
      icon: Icons.account_balance_outlined,
      accent: AppColors.accueilFinancesAccent,
      softBackground: AppColors.accueilFinancesSoft,
      subModules: [
        _dashboard(
          l10n,
          menuId: menuId,
          subMenuId: MenuConstants.financesDashboardId,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.facturationsId,
          title: l10n.subMenuBilling,
        ),
      ],
    );
  }

  /// Le contrôle des frais — une carte propre, comme le menu.
  ///
  /// La synthèse d'abord, les noms ensuite : l'en-tête ouvre le tableau de
  /// bord, qui pose la question, et la seconde ligne mène à l'écran qui donne
  /// les noms. Finances porte les gestes de caisse ; ce module n'en accomplit
  /// aucun — il regarde qui a réglé.
  static AccueilModule _feeControl(AppLocalizations l10n) {
    const menuId = MenuConstants.feeControlMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuFeeControl,
      description: l10n.accueilModuleFeeControlDescription,
      icon: Icons.fact_check_outlined,
      accent: AppColors.accueilFeeControlAccent,
      softBackground: AppColors.accueilFeeControlSoft,
      subModules: [
        _dashboard(
          l10n,
          menuId: menuId,
          subMenuId: MenuConstants.feeControlDashboardId,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.feeControlId,
          title: l10n.subMenuFeeControl,
        ),
      ],
    );
  }

  /// La caisse boutique — une carte propre, comme le menu.
  ///
  /// Sans tableau de bord : la caisse a un guichet et un historique, pas de
  /// synthèse ; sa page d'entrée est donc son premier sous-module (Achats).
  static AccueilModule _boutique(AppLocalizations l10n) {
    const menuId = MenuConstants.boutiqueMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuBoutique,
      description: l10n.accueilModuleBoutiqueDescription,
      icon: Icons.storefront_outlined,
      accent: AppColors.accueilBoutiqueAccent,
      softBackground: AppColors.accueilBoutiqueSoft,
      subModules: [
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.boutiqueAchatsId,
          title: l10n.subMenuBoutiquePurchases,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.boutiqueHistoriqueId,
          title: l10n.subMenuBoutiqueHistory,
        ),
      ],
    );
  }

  static AccueilModule _classes(AppLocalizations l10n) {
    const menuId = MenuConstants.classesMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuClasses,
      description: l10n.accueilModuleClassesDescription,
      icon: Icons.grid_view_outlined,
      accent: AppColors.accueilClassesAccent,
      softBackground: AppColors.accueilClassesSoft,
      subModules: [
        _dashboard(
          l10n,
          menuId: menuId,
          subMenuId: MenuConstants.classesDashboardId,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.organisationId,
          title: l10n.subMenuOrganization,
          label: l10n.subMenuOrganization.replaceAll('\n', ' '),
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.classesListId,
          title: l10n.subMenuClassesList,
        ),
      ],
    );
  }

  /// Cours — pas de tableau de bord : l'en-tête ouvre « Emploi du temps »,
  /// premier sous-module de la liste (spec §03, note « page d'entrée »).
  static AccueilModule _cours(AppLocalizations l10n) {
    const menuId = MenuConstants.coursesMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuCourses,
      description: l10n.accueilModuleCoursDescription,
      icon: Icons.menu_book_outlined,
      accent: AppColors.accueilCoursAccent,
      softBackground: AppColors.accueilCoursSoft,
      subModules: [
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.timetableId,
          title: l10n.subMenuTimetable,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.myCoursesId,
          title: l10n.subMenuMyCourses,
        ),
      ],
    );
  }

  /// Résultats — page unique : l'en-tête et l'unique ligne mènent au même écran.
  static AccueilModule _resultats(AppLocalizations l10n) {
    const menuId = MenuConstants.resultatsMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuResultats,
      description: l10n.accueilModuleResultatsDescription,
      icon: Icons.percent,
      accent: AppColors.accueilResultatsAccent,
      softBackground: AppColors.accueilResultatsSoft,
      subModules: [
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.resultatsClasseId,
          title: l10n.subMenuResultatsClasse,
        ),
      ],
    );
  }

  static AccueilModule _disciplines(AppLocalizations l10n) {
    const menuId = MenuConstants.disciplinesMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuDisciplines,
      description: l10n.accueilModuleDisciplinesDescription,
      icon: Icons.school_outlined,
      accent: AppColors.accueilDisciplinesAccent,
      softBackground: AppColors.accueilDisciplinesSoft,
      subModules: [
        _dashboard(
          l10n,
          menuId: menuId,
          subMenuId: MenuConstants.disciplinesDashboardId,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.presencesId,
          title: l10n.subMenuAttendance,
        ),
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.disciplinesListId,
          title: l10n.subMenuDisciplinesList,
        ),
      ],
    );
  }

  /// Configuration — page unique, et la seule carte qui ne serve pas un métier
  /// quotidien : elle n'apparaît qu'à qui détient `school.provisioning.write`,
  /// c'est-à-dire à la direction.
  static AccueilModule _configuration(AppLocalizations l10n) {
    const menuId = MenuConstants.configurationMenuId;
    return AccueilModule(
      id: menuId,
      title: l10n.menuConfiguration,
      description: l10n.accueilModuleConfigurationDescription,
      icon: Icons.tune_rounded,
      accent: AppColors.accueilConfigurationAccent,
      softBackground: AppColors.accueilConfigurationSoft,
      subModules: [
        _page(
          menuId: menuId,
          subMenuId: MenuConstants.configurationSchoolId,
          title: l10n.subMenuConfigurationSchool,
        ),
      ],
    );
  }
}
