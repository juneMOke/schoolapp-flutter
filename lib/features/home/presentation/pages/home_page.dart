import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_feature_scope.dart';
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
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
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
          final isMobile = constraints.maxWidth < AppBreakpoints.homeMobileMax;

          if (isMobile) {
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
                  const TopBar(),
                  Expanded(child: _buildMainContent(context, state)),
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
          appBar: const TopBar(),
          drawer: const Drawer(child: Sidebar()),
          body: _buildMainContent(context, state),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, NavigationState state) {
    final hidePageBreadcrumb =
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
        state.selectedSubMenuId == MenuConstants.disciplinesListId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hidePageBreadcrumb) ...[
            _buildBreadcrumb(context, state),
            const SizedBox(height: AppDimensions.spacingL),
          ],
          Expanded(child: _buildContentArea(context, state)),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, NavigationState state) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l10n.home,
          style: AppTextStyles.body.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        if (state.selectedMenuId != null) ...[
          const Text(
            ' / ',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          Text(
            state.menuItems
                .firstWhere((menu) => menu.id == state.selectedMenuId)
                .title,
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
    );
  }

  Widget _buildContentArea(BuildContext context, NavigationState state) {
    return _getContentForRoute(context, state);
  }

  Widget _getContentForRoute(BuildContext context, NavigationState state) {
    final l10n = AppLocalizations.of(context)!;

    switch (state.selectedSubMenuId) {
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
