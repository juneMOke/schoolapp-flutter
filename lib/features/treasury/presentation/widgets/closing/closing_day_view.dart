import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_screen.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_status_banner.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/closing_report_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La journée de Clôture de caisse (B2–B5) : son état, une carte par caisse
/// et le rapport du jour. Seule en Journalier ; à côté de la semaine ou du
/// mois sur un écran large.
class ClosingDayView extends StatelessWidget {
  final CashClosingState state;
  final ClosingCallbacks callbacks;
  final bool online;

  const ClosingDayView({
    super.key,
    required this.state,
    required this.callbacks,
    required this.online,
  });

  @override
  Widget build(BuildContext context) => _body(context, state);

  Widget _body(BuildContext context, CashClosingState state) {
    final l10n = AppLocalizations.of(context)!;
    final day = state.day;
    final configure = callbacks.configure;
    return switch (state.status) {
      CashClosingStatus.loading => EteeloListSkeleton(
        rowCount: 2,
        pillCount: 2,
        showAvatar: false,
        semanticsLabel: l10n.treasuryDayLoading,
      ),
      CashClosingStatus.failure => TreasuryResultsErrorState(
        failure: state.failure ?? const ServerFailure(),
        onRetry: context.read<CashClosingCubit>().load,
      ),
      _ when day == null || day.registers.isEmpty => EteeloEmptyResult(
        label: l10n.treasuryEmptyTitle,
        description: l10n.treasuryEmptyClosing,
        medallionIcon: Icons.payments_outlined,
        fullWidthCard: true,
        primaryAction: configure == null
            ? null
            : EteeloButton.primary(
                label: l10n.treasuryConfigureRegisters,
                icon: Icons.settings_outlined,
                onPressed: configure,
                fullWidth: false,
              ),
      ),
      _ => _day(context, state, day),
    };
  }

  Widget _day(BuildContext context, CashClosingState state, TreasuryDay day) {
    final blocks = {
      for (final summary in day.registers)
        summary.register.id: CashClosingRules.blockOf(
          isToday: day.isToday,
          sunday: state.sunday,
          closed: summary.isClosed,
          canClose: callbacks.close != null,
          online: online,
          pendingSyncCount: state.pendingSync[summary.register.currency] ?? 0,
          pendingAfterClosureCount: summary.pendingAfterClosureCount,
        ),
    };
    final close = callbacks.close;
    final next = day.registers
        .where((s) => blocks[s.register.id] == null)
        .firstOrNull;
    // Une ligne arrivée après une clôture se règle sur sa propre journée,
    // même passée : le serveur compte toutes celles qui attendent jusqu'à
    // aujourd'hui, et refuserait la clôture du jour tant qu'il en reste une.
    final answer = online ? callbacks.answer : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayStatusBanner(
          day: day,
          nextRegisterName: next?.register.name,
          onCloseNext: next == null || close == null ? null : () => close(next),
        ),
        const SizedBox(height: AppSpacing.lg),
        EteeloGridView(
          itemCount: day.registers.length,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasuryDayCardMinWidth,
          spacing: AppSpacing.lg,
          itemBuilder: (context, index) {
            final summary = day.registers[index];
            final reopen = callbacks.reopen;
            return DayCard(
              key: ValueKey('${summary.register.id}-${day.date}'),
              summary: summary,
              date: day.date,
              isToday: day.isToday,
              block: blocks[summary.register.id],
              pendingSyncCount:
                  state.pendingSync[summary.register.currency] ?? 0,
              onClose: close == null ? null : () => close(summary),
              onReopen:
                  reopen != null && online && day.isToday && summary.isClosed
                  ? () => reopen(summary)
                  : null,
              onAnswer: answer,
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ClosingReportBar(
          label: AppLocalizations.of(context)!.treasuryReportOneDaily,
          title: capitalizeFirst(
            AppLocalizations.of(context)!.treasuryDayLong(day.date),
          ),
          reportId: CashReportIds.daily(day.date),
          remainingRegisters: day.registers.length - day.closedCount,
          pastNotClosed: !day.isToday && day.closedCount < day.registers.length,
        ),
      ],
    );
  }
}
