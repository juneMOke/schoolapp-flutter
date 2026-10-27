import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_agent_situations.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_agent_navigation.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_hero.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_month_list.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_month_panel.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_profile_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le rang de l'agent dans le livre d'entrée, et de quoi passer à son voisin
/// — `null` aux extrémités, ou hors du livre.
class PayrollAgentStepper {
  final int index;
  final int count;
  final VoidCallback? previous;
  final VoidCallback? next;

  const PayrollAgentStepper._(this.index, this.count, this.previous, this.next);

  factory PayrollAgentStepper.of(
    BuildContext context,
    PayrollState state, {
    required String agentId,
    required String entryMonth,
  }) {
    final view = state.history.where((v) => v.month == entryMonth).firstOrNull;
    final roster = view == null
        ? const <String>[]
        : PayrollAgentSituations.roster(state.snapshot, view);
    final index = roster.indexOf(agentId);
    VoidCallback? to(int at) => index < 0 || at < 0 || at >= roster.length
        ? null
        : () => PayrollAgentNavigation.step(
            context,
            agentId: roster[at],
            month: entryMonth,
          );
    return PayrollAgentStepper._(
      index,
      index < 0 ? 0 : roster.length,
      to(index - 1),
      to(index + 1),
    );
  }
}

/// La fiche une fois la tablette lue : le bandeau, puis la colonne des
/// mois et des engagements à côté du panneau du mois — l'un sous l'autre sur
/// un écran étroit, le mois choisi avant les prêts et les cumuls.
class PayrollAgentBody extends StatefulWidget {
  final PayrollState state;
  final String agentId;
  final PayrollAgentStepper stepper;

  const PayrollAgentBody({
    super.key,
    required this.state,
    required this.agentId,
    required this.stepper,
  });

  @override
  State<PayrollAgentBody> createState() => _PayrollAgentBodyState();
}

class _PayrollAgentBodyState extends State<PayrollAgentBody> {
  final _panelKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final situation = PayrollAgentSituations.of(
      state.snapshot,
      state.history,
      staffMemberId: widget.agentId,
      year: state.month.substring(0, 4),
      currentMonth: state.currentMonth,
    );
    if (situation.months.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.payrollAgentEmpty,
        description: l10n.payrollAgentEmptyHint,
        medallionIcon: Icons.receipt_long_outlined,
        fullWidthCard: true,
        primaryAction: EteeloButton.primary(
          label: l10n.payrollAgentBackToLedger,
          icon: Icons.arrow_back,
          onPressed: () => PayrollAgentNavigation.leave(context),
          fullWidth: false,
        ),
      );
    }
    final shown = situation.monthOf(state.month) ?? situation.months.first;
    if (shown.month != state.month) _follow(shown.month);
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final hero = PayrollAgentHero(
      member: state.snapshot.member(widget.agentId),
      staffMemberId: widget.agentId,
      contractKind: situation.months.first.line.contractKind,
      profile: state.snapshot.profiles[widget.agentId],
      situation: situation,
      index: widget.stepper.index,
      count: widget.stepper.count,
      onPrevious: widget.stepper.previous,
      onNext: widget.stepper.next,
      onEditProfile: canWrite
          ? () => PayrollProfileDialog.edit(context, widget.agentId)
          : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AppBreakpoints.payrollAgentTwoColumnsMin;
        final months = PayrollAgentMonthList(
          months: situation.months,
          selected: shown.month,
          onSelect: (month) => _select(month, scroll: !wide),
        );
        final panel = KeyedSubtree(
          key: _panelKey,
          child: PayrollAgentMonthPanel(snapshot: state.snapshot, month: shown),
        );
        final side = _side(situation);
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: AppSpacing.lg),
              months,
              const SizedBox(height: AppSpacing.lg),
              panel,
              for (final card in side) ...[
                const SizedBox(height: AppSpacing.lg),
                card,
              ],
            ],
          );
        }
        final sideWidth = (constraints.maxWidth * 0.32).clamp(
          AppDimensions.payrollAgentSideMin,
          AppDimensions.payrollAgentSideMax,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: sideWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      months,
                      for (final card in side) ...[
                        const SizedBox(height: AppSpacing.md),
                        card,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: panel),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Les engagements de l'agent : prêts, arriérés, cumuls.
  List<Widget> _side(PayrollAgentSituation situation) => const [];

  /// Le mois affiché porte les gestes du cubit : il le suit.
  void _follow(String month) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PayrollCubit>().showMonth(month);
      });

  void _select(String month, {required bool scroll}) {
    context.read<PayrollCubit>().showMonth(month);
    if (!scroll) return;
    // Sur un écran étroit, le panneau est sous la liste : on l'amène.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _panelKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target, alignment: 0.0);
      }
    });
  }
}
