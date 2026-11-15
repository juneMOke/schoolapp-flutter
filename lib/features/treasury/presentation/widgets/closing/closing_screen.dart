import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_status_banner.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de l'écran, câblés par la page ; `null` quand ils ne sont pas
/// offerts (droits).
class ClosingCallbacks {
  final void Function(CashDaySummary summary)? close;
  final void Function(CashDaySummary summary)? reopen;
  final Future<void> Function(CashMovement movement, bool alreadyCounted)?
  answer;
  final VoidCallback? configure;

  const ClosingCallbacks({
    this.close,
    this.reopen,
    this.answer,
    this.configure,
  });
}

/// Trésorerie ▸ Clôture de caisse, vue journalière (B1–B5).
class ClosingScreen extends StatelessWidget {
  final ClosingCallbacks callbacks;
  final bool online;

  const ClosingScreen({
    super.key,
    required this.callbacks,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CashClosingCubit, CashClosingState>(
      builder: (context, state) {
        final cubit = context.read<CashClosingCubit>();
        final businessDate = state.businessDate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              eyebrow: l10n.menuTreasury,
              title: l10n.treasuryClosingTitle,
              subtitle: l10n.treasuryClosingSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            // La barre reste dès que le serveur a dit quel jour on est, même
            // si la journée affichée échoue : on peut toujours en sortir.
            if (businessDate != null) ...[
              DayNavBar(
                date: state.date,
                isToday: state.date == businessDate,
                onPrevious: cubit.nextDay(-1) == null
                    ? null
                    : () => cubit.step(-1),
                onNext: cubit.nextDay(1) == null ? null : () => cubit.step(1),
                onToday: cubit.goToday,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _body(context, state),
          ],
        );
      },
    );
  }

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
      ],
    );
  }
}
