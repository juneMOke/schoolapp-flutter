import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/reports_panel.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_overview_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/evolution_panel.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/register_kpi_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_location_sync.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trésorerie ▸ Tableau de bord (A1-A4) : combien chaque caisse détient,
/// puis leur évolution. Chaque caisse dans sa devise, jamais additionnées.
class TreasuryDashboardScreen extends StatelessWidget {
  /// La clôture de la caisse, journée du jour (A2). `null` sans le droit.
  final VoidCallback? onOpenClosing;

  /// La configuration des caisses (état vide). `null` sans le droit.
  final VoidCallback? onConfigure;

  /// Coutures de test : fabriquent les cubits à partir du jour du serveur.
  final TreasuryEvolutionCubit Function(DateTime today)? evolutionCubit;
  final CashReportsCubit Function(DateTime today)? reportsCubit;

  const TreasuryDashboardScreen({
    super.key,
    this.onOpenClosing,
    this.onConfigure,
    this.evolutionCubit,
    this.reportsCubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TreasuryOverviewCubit, TreasuryOverviewState>(
      builder: (context, state) {
        final overview = state.overview;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              eyebrow: overview == null
                  ? l10n.menuTreasury
                  : l10n.treasuryEyebrowYear(overview.academicYear.name),
              title: l10n.treasuryDashboardTitle,
              titleStyle: TreasuryTitle.style(context),
              subtitle: overview == null
                  ? null
                  : l10n.treasuryDashboardSubtitle(overview.businessDate),
            ),
            const SizedBox(height: AppSpacing.xl),
            switch (state.status) {
              TreasuryOverviewStatus.loading => EteeloListSkeleton(
                rowCount: 3,
                pillCount: 2,
                showAvatar: false,
                semanticsLabel: l10n.treasuryDashboardLoading,
              ),
              TreasuryOverviewStatus.failure => TreasuryResultsErrorState(
                notFoundMeansNoYear: true,
                failure: state.failure ?? const ServerFailure(),
                onRetry: context.read<TreasuryOverviewCubit>().load,
              ),
              _ when overview == null || overview.registers.isEmpty => _empty(
                l10n,
              ),
              _ => _content(overview),
            },
          ],
        );
      },
    );
  }

  Widget _empty(AppLocalizations l10n) {
    final configure = onConfigure;
    return EteeloEmptyResult(
      label: l10n.treasuryEmptyTitle,
      description: l10n.treasuryEmptyDashboard,
      medallionIcon: Icons.payments_outlined,
      fullWidthCard: true,
      primaryAction: configure == null
          ? null
          : EteeloButton.primary(
              label: l10n.treasuryCreateRegister,
              icon: Icons.add,
              onPressed: configure,
              fullWidth: false,
            ),
    );
  }

  Widget _content(TreasuryOverview overview) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EteeloGridView(
        itemCount: overview.registers.length,
        padding: EdgeInsets.zero,
        minItemWidth: AppDimensions.treasuryKpiCardMinWidth,
        spacing: AppSpacing.lg,
        itemBuilder: (context, index) => RegisterKpiCard(
          overview: overview.registers[index],
          onOpen: onOpenClosing,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      TreasuryPanel(
        child: Padding(
          padding: EdgeInsets.zero,
          // L'évolution naît une fois le jour du serveur connu : la plage
          // libre en part, jamais de l'horloge de la tablette (R15).
          child: BlocProvider(
            create: (_) =>
                evolutionCubit?.call(overview.businessDate) ??
                TreasuryEvolutionCubit(
                  GetIt.instance<TreasuryDashboardRepository>(),
                  today: overview.businessDate,
                ),
            // Il lance la première lecture, sur l'adresse.
            child: EvolutionLocationSync(
              child: EvolutionPanel(
                firstDay: overview.academicYear.startDate,
                today: overview.businessDate,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      TreasuryPanel(
        child: Padding(
          padding: EdgeInsets.zero,
          child: BlocProvider(
            create: (_) =>
                reportsCubit?.call(overview.businessDate) ??
                CashReportsCubit(
                  GetIt.instance<TreasuryReportsRepository>(),
                  today: overview.businessDate,
                ),
            child: ReportsLocationSync(
              child: ReportsPanel(
                firstDay: overview.academicYear.startDate,
                today: overview.businessDate,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
