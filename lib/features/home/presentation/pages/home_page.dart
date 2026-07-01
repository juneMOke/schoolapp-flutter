import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_feature_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_overview_dashboard_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_overview_dashboard_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/presences_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/re_registrations_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_feature_scope.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_list_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/courses_coordinator_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/courses_feature_scope.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  final String? initialSubMenuId;

  const HomePage({super.key, this.initialSubMenuId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) {
        final bloc = NavigationBloc(l10n);
        final initialSubMenuId = this.initialSubMenuId?.trim();
        if (initialSubMenuId == null || initialSubMenuId.isEmpty) {
          return bloc;
        }

        for (final menu in bloc.state.menuItems) {
          for (final subMenu in menu.subMenus) {
            if (subMenu.id == initialSubMenuId) {
              bloc.add(
                SubMenuItemSelected(
                  menuId: menu.id,
                  subMenuId: subMenu.id,
                  title: subMenu.title,
                ),
              );
              return bloc;
            }
          }
        }

        return bloc;
      },
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < AppBreakpoints.navigationCompactMax;

          if (isCompact) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) =>
          previous.isSidebarExpanded != current.isSidebarExpanded ||
          previous.currentTitle != current.currentTitle ||
          previous.selectedMenuId != current.selectedMenuId ||
          previous.selectedSubMenuId != current.selectedSubMenuId,
      builder: (context, state) {
        return Row(
          children: [
            const Sidebar(),
            Expanded(
              child: Column(
                children: [
                  const TopBar(isCompact: false),
                  Expanded(
                    child: _buildMainContent(context, state, isCompact: false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) =>
          previous.currentTitle != current.currentTitle ||
          previous.selectedMenuId != current.selectedMenuId ||
          previous.selectedSubMenuId != current.selectedSubMenuId,
      builder: (context, state) {
        return Scaffold(
          drawerScrimColor: AppColors.bleuProfond.withValues(alpha: 0.4),
          appBar: const TopBar(isCompact: true),
          drawer: const Drawer(
            width: AppTheme.sidebarWidth,
            elevation: 12,
            // Tiroir : sidebar toujours déployée (ignore le repli 84 du bureau).
            child: Sidebar(
              closeDrawerOnSubMenuSelection: true,
              forceExpanded: true,
            ),
          ),
          body: _buildMainContent(context, state, isCompact: true),
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    NavigationState state, {
    required bool isCompact,
  }) {
    final hidePageBreadcrumb =
        state.selectedSubMenuId == MenuConstants.accueilId ||
        state.selectedSubMenuId == MenuConstants.inscriptionsDashboardId ||
        state.selectedSubMenuId == MenuConstants.financesDashboardId ||
        state.selectedSubMenuId == MenuConstants.classesDashboardId ||
        state.selectedSubMenuId == MenuConstants.preInscriptionsId ||
        state.selectedSubMenuId == MenuConstants.reInscriptionsId ||
        state.selectedSubMenuId == MenuConstants.premiereInscriptionId ||
        state.selectedSubMenuId == MenuConstants.facturationsId ||
        state.selectedSubMenuId == MenuConstants.organisationId ||
        state.selectedSubMenuId == MenuConstants.classesListId ||
        state.selectedSubMenuId == MenuConstants.presencesId ||
        state.selectedSubMenuId == MenuConstants.disciplinesListId ||
        state.selectedSubMenuId == MenuConstants.disciplinesDashboardId ||
        state.selectedSubMenuId == MenuConstants.myCoursesId;

    // Pages plein-cadre (sans fil d'Ariane) : elles peignent déjà leur propre
    // fond Kuba et gèrent padding + centrage via AppPageBackground. On leur
    // donne TOUT le volet pour que le fond couvre l'intégralité de la page
    // (gouttières et marges comprises), au lieu de le confiner dans une boîte
    // paddée/centrée par la coquille (ce qui évite aussi un double padding).
    if (hidePageBreadcrumb) {
      return _buildContentArea(context, state);
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreadcrumb(context, state),
        const SizedBox(height: AppDimensions.spacingL),
        Expanded(child: _buildContentArea(context, state)),
      ],
    );

    return Padding(
      // Padding contenu : 16 dp en compact, 24 dp en bureau.
      padding: EdgeInsets.all(
        isCompact ? AppDimensions.spacingM : AppDimensions.spacingL,
      ),
      // Bureau : contenu plafonné à 1180 dp et centré ; compact : pleine largeur.
      child: isCompact
          ? content
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.detailContentMaxWidth,
                ),
                child: content,
              ),
            ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, NavigationState state) {
    final l10n = AppLocalizations.of(context)!;
    // Lookup tolérant : un selectedMenuId qui ne correspondrait à aucun menu
    // (état incohérent) ne doit jamais faire planter le fil d'Ariane.
    final selectedMenuMatches = state.menuItems.where(
      (menu) => menu.id == state.selectedMenuId,
    );
    final selectedMenuTitle = selectedMenuMatches.isEmpty
        ? null
        : selectedMenuMatches.first.title;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.home,
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          if (selectedMenuTitle != null) ...[
            const Text(
              ' / ',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            Text(
              selectedMenuTitle,
              style: AppTextStyles.body.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
          if (state.selectedSubMenuId != null) ...[
            const Text(
              ' / ',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            Text(
              state.currentTitle,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, NavigationState state) {
    return _getContentForRoute(context, state);
  }

  Widget _getContentForRoute(BuildContext context, NavigationState state) {
    final l10n = AppLocalizations.of(context)!;

    switch (state.selectedSubMenuId) {
      case MenuConstants.accueilId:
        return const AccueilPage();
      case MenuConstants.inscriptionsDashboardId:
        return const EnrollmentStatsDashboardScope(
          child: EnrollmentStatsDashboardPage(),
        );
      case MenuConstants.preInscriptionsId:
        return const EnrollmentFeatureScope(child: PreRegistrationsPage());
      case MenuConstants.reInscriptionsId:
        return const EnrollmentFeatureScope(child: ReRegistrationsPage());
      case MenuConstants.premiereInscriptionId:
        return const EnrollmentFeatureScope(child: FirstRegistrationPage());
      case MenuConstants.facturationsId:
        return const FinanceFeatureScope(child: FacturationPage());
      case MenuConstants.financesDashboardId:
        return const FinanceStatsDashboardScope(
          child: FinanceStatsDashboardPage(),
        );
      case MenuConstants.classesDashboardId:
        return const ClassesFeatureScope(child: ClassesStatsDashboardPage());
      case MenuConstants.organisationId:
        return const ClassesFeatureScope(child: ClassesOrganisationPage());
      case MenuConstants.classesListId:
        return const ClassesFeatureScope(
          child: ClassesListPage(intent: ClassesListIntent.classesList()),
        );
      case MenuConstants.presencesId:
        return const AttendanceFeatureScope(child: PresencesPage());
      case MenuConstants.disciplinesListId:
        return const ClassesFeatureScope(
          child: ClassesListPage(intent: ClassesListIntent.disciplinesList()),
        );
      case MenuConstants.disciplinesDashboardId:
        return const AttendanceOverviewDashboardScope(
          child: AttendanceOverviewDashboardPage(),
        );
      case MenuConstants.myCoursesId:
        return const CoursesFeatureScope(child: CoursesCoordinatorPage());
      default:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  state.currentTitle,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  l10n.pageUnderConstruction,
                  style: AppTextStyles.body.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
