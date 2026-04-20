import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/re_registrations_page.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => NavigationBloc(l10n),
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
          final isMobile = constraints.maxWidth < 768;

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
    final hideBreadcrumbForEnrollment =
        state.selectedSubMenuId == MenuConstants.preInscriptionsId ||
        state.selectedSubMenuId == MenuConstants.reInscriptionsId ||
        state.selectedSubMenuId == MenuConstants.premiereInscriptionId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideBreadcrumbForEnrollment) ...[
            _buildBreadcrumb(context, state),
            const SizedBox(height: AppTheme.largePadding),
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
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
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
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
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
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      case MenuConstants.preInscriptionsId:
        return const EnrollmentFeatureScope(child: PreRegistrationsPage());
      case MenuConstants.reInscriptionsId:
        return const EnrollmentFeatureScope(child: ReRegistrationsPage());
      case MenuConstants.premiereInscriptionId:
        return const EnrollmentFeatureScope(child: FirstRegistrationPage());
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
          padding: const EdgeInsets.all(AppTheme.largePadding),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  state.currentTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.pageUnderConstruction,
                  style: const TextStyle(
                    fontSize: 16,
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
