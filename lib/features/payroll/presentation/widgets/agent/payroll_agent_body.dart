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
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_arrears_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_hero.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_loans_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_totals_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_month_list.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_month_panel.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_stepper.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_profile_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fiche une fois la tablette lue : le bandeau, puis la colonne des
/// mois et des engagements à côté du panneau du mois — l'un sous l'autre sur
/// un écran étroit, le mois choisi en tête, puis la liste des mois, les
/// prêts et les cumuls.
class PayrollAgentBody extends StatefulWidget {
  final PayrollState state;
  final String agentId;
  final String entryMonth;

  /// L'écran sous la fiche (le livre, le tableau de bord).
  final String origin;
  final PayrollAgentStepper stepper;

  const PayrollAgentBody({
    super.key,
    required this.state,
    required this.agentId,
    required this.entryMonth,
    required this.origin,
    required this.stepper,
  });

  @override
  State<PayrollAgentBody> createState() => _PayrollAgentBodyState();
}

class _PayrollAgentBodyState extends State<PayrollAgentBody> {
  final _panelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Passer à l'agent voisin garde le cubit de la page : la fiche repart
    // du mois d'entrée et du haut de page, comme un F5 sur son adresse.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<PayrollCubit>();
      if (cubit.state.month != widget.entryMonth) {
        cubit.showMonth(widget.entryMonth);
      }
      final scroll = Scrollable.maybeOf(context)?.position;
      if (scroll != null && scroll.hasPixels && scroll.pixels > 0) {
        scroll.jumpTo(scroll.minScrollExtent);
      }
    });
  }

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
          label: PayrollAgentNavigation.backLabel(l10n, widget.origin),
          icon: Icons.arrow_back,
          size: EteeloButtonSize.regular,
          onPressed: () =>
              PayrollAgentNavigation.leave(context, from: widget.origin),
          fullWidth: false,
        ),
      );
    }
    final shown = situation.monthOf(state.month) ?? situation.months.first;
    if (shown.month != state.month) _follow(shown.month, seen: state.month);
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
        final side = _side(situation, shown, canWrite: canWrite, wide: wide);
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: AppSpacing.lg),
              // Le mois choisi d'abord : la liste des mois peut être longue.
              panel,
              const SizedBox(height: AppSpacing.lg),
              months,
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
  List<Widget> _side(
    PayrollAgentSituation situation,
    PayrollAgentMonth shown, {
    required bool canWrite,
    required bool wide,
  }) {
    final state = widget.state;
    final arrears = situation.arrears;
    return [
      PayrollAgentLoansCard(
        situation: situation,
        snapshot: state.snapshot,
        view: shown.view,
      ),
      PayrollAgentArrearsCard(
        arrears: arrears,
        onSelectMonth: (month) => _select(month, scroll: !wide),
        canWrite: canWrite,
        onOpen: () {
          if (arrears != null) {
            PayrollArrearsActions(context).open(arrears, state.currentMonth);
          }
        },
      ),
      if (situation.totals.isNotEmpty)
        PayrollAgentTotalsCard(year: situation.year, totals: situation.totals),
    ];
  }

  /// Le mois affiché porte les gestes du cubit : il le suit — sauf si le
  /// cubit a changé de mois entre-temps (retour au mois d'entrée).
  void _follow(String month, {required String seen}) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cubit = context.read<PayrollCubit>();
        if (cubit.state.month == seen) cubit.showMonth(month);
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
