import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_row.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les rapports de caisse (A5) : Journaliers · Hebdomadaires · Mensuels ·
/// Annuels listés par le serveur, huit par page ; « Période » générée à la
/// demande et gardée le temps de la session.
class ReportsPanel extends StatelessWidget {
  /// Bornes du sélecteur de « Période ».
  final DateTime firstDay;
  final DateTime today;

  const ReportsPanel({super.key, required this.firstDay, required this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CashReportsCubit, CashReportsState>(
      builder: (context, state) {
        final cubit = context.read<CashReportsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.terreCuite,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.treasuryReportsTitle,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        l10n.treasuryReportsSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedTabFilter<CashReportKind>(
              semanticsLabel: l10n.treasuryReportsTitle,
              selected: state.kind,
              onSelected: cubit.kindChanged,
              wrap: true,
              options: [
                SegmentedTabOption(
                  label: l10n.treasuryReportKindDaily,
                  value: CashReportKind.daily,
                  icon: Icons.schedule,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryReportKindWeekly,
                  value: CashReportKind.weekly,
                  icon: Icons.calendar_today_outlined,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryReportKindMonthly,
                  value: CashReportKind.monthly,
                  icon: Icons.date_range,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryReportKindYearly,
                  value: CashReportKind.yearly,
                  icon: Icons.event_available,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryReportKindPeriod,
                  value: CashReportKind.period,
                  icon: Icons.filter_alt_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.kind == CashReportKind.period)
              _PeriodReports(state: state, firstDay: firstDay, today: today)
            else
              _listed(context, state),
          ],
        );
      },
    );
  }

  Widget _listed(BuildContext context, CashReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CashReportsCubit>();
    final page = state.page;
    return switch (state.status) {
      CashReportsStatus.loading => EteeloListSkeleton(
        rowCount: 3,
        pillCount: 2,
        showAvatar: false,
        semanticsLabel: l10n.treasuryReportsLoading,
      ),
      CashReportsStatus.failure => TreasuryResultsErrorState(
        failure: state.failure ?? const ServerFailure(),
        onRetry: () => cubit.load(state.requestedPage),
      ),
      CashReportsStatus.ready when page == null || page.items.isEmpty => Text(
        l10n.treasuryReportsEmpty,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportList(reports: page!.items, today: today),
          if (page.totalPages > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: l10n.treasuryPagePrev,
                  onPressed: page.number > 0
                      ? () => cubit.load(page.number - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  l10n.treasuryPageOf(page.number + 1, page.totalPages),
                  style: AppTypography.bodySmall,
                ),
                IconButton(
                  tooltip: l10n.treasuryPageNext,
                  onPressed: page.number + 1 < page.totalPages
                      ? () => cubit.load(page.number + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ],
      ),
    };
  }
}

class _ReportList extends StatelessWidget {
  final List<CashReport> reports;
  final DateTime today;

  const _ReportList({required this.reports, required this.today});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(
      borderRadius: AppRadius.brMd,
      child: Column(
        children: [
          for (final (index, report) in reports.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            ReportRow(
              key: ValueKey(report.id),
              report: report,
              isToday:
                  report.kind == CashReportKind.daily && report.from == today,
            ),
          ],
        ],
      ),
    ),
  );
}

/// « Période » : Du / Au (14 derniers jours par défaut), « Générer le
/// rapport », puis les rapports générés pendant la session.
class _PeriodReports extends StatelessWidget {
  final CashReportsState state;
  final DateTime firstDay;
  final DateTime today;

  const _PeriodReports({
    required this.state,
    required this.firstDay,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CashReportsCubit>();
    final localizations = MaterialLocalizations.of(context);
    Future<void> pick(bool isFrom) async {
      final initial = isFrom ? state.customFrom : state.customTo;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(firstDay)
            ? firstDay
            : initial.isAfter(today)
            ? today
            : initial,
        firstDate: firstDay,
        lastDate: today,
      );
      if (picked == null || !context.mounted) return;
      cubit.rangeChanged(
        isFrom ? picked : state.customFrom,
        isFrom ? state.customTo : picked,
      );
    }

    Future<void> generate() async {
      final failure = await cubit.generatePeriod();
      if (failure != null && context.mounted) {
        AppSnackBar.showError(
          context,
          l10n.treasurySaveFailed(l10n.treasuryFailureReason(failure)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            EteeloButton.secondary(
              label:
                  '${l10n.treasuryRangeFrom} '
                  '${localizations.formatMediumDate(state.customFrom)}',
              icon: Icons.calendar_today_outlined,
              onPressed: () => pick(true),
              fullWidth: false,
            ),
            EteeloButton.secondary(
              label:
                  '${l10n.treasuryRangeTo} '
                  '${localizations.formatMediumDate(state.customTo)}',
              icon: Icons.calendar_today_outlined,
              onPressed: () => pick(false),
              fullWidth: false,
            ),
            EteeloButton.primary(
              label: l10n.treasuryReportGenerate,
              icon: Icons.add,
              isLoading: state.generating,
              onPressed: state.rangeInvalid || state.generating
                  ? null
                  : generate,
              fullWidth: false,
            ),
          ],
        ),
        if (state.rangeInvalid) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.treasuryRangeInvalid,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (state.periodReports.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  l10n.treasuryReportEmptyTitle,
                  style: AppTypography.titleSmall,
                ),
                Text(
                  l10n.treasuryReportEmptyBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          _ReportList(reports: state.periodReports, today: today),
      ],
    );
  }
}
