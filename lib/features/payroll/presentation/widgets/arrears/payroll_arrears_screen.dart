import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_agent_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_tiles.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les puces du registre ; la valeur du fil est celle de l'adresse.
enum PayrollArrearsFilter {
  all(null),
  deferred('differes'),
  unpaid('impayes'),
  prioritized('priorite');

  const PayrollArrearsFilter(this.wire);
  final String? wire;

  static PayrollArrearsFilter fromWire(String? value) =>
      values.firstWhere((filter) => filter.wire == value, orElse: () => all);

  bool keeps(PayrollArrearsAgent agent) => switch (this) {
    all => true,
    deferred => agent.origins.contains(PayrollArrearOrigin.deferred),
    unpaid => agent.origins.any((o) => o != PayrollArrearOrigin.deferred),
    prioritized => agent.prioritized,
  };
}

/// RH · Paie ▸ Arriérés : tout ce que l'école doit encore à ses agents sur
/// des paies validées, chaque montant rattaché à son mois d'origine. Lecture
/// 100 % locale ; un versement d'arriérés est un versement ordinaire.
class PayrollArrearsScreen extends StatefulWidget {
  const PayrollArrearsScreen({super.key});

  @override
  State<PayrollArrearsScreen> createState() => _PayrollArrearsScreenState();
}

class _PayrollArrearsScreenState extends State<PayrollArrearsScreen> {
  PayrollArrearsFilter _filter = PayrollArrearsFilter.all;
  String _search = '';

  static const String _filterKey = 'filtre';

  @override
  Widget build(BuildContext context) => AppPageBackground(
    width: PageContentWidth.wide,
    child: LocationParamsSync(
      current: {_filterKey: _filter.wire},
      onLocation: (values) => setState(
        () => _filter = PayrollArrearsFilter.fromWire(values[_filterKey]),
      ),
      child: BlocConsumer<PayrollCubit, PayrollState>(
        listenWhen: (previous, current) =>
            current.notice != null && previous.notice != current.notice,
        listener: (context, state) => showPayrollNotice(
          context,
          state.notice!,
          monthLabel: PayrollLabels.month(context, state.month),
        ),
        buildWhen: (previous, current) =>
            previous.load != current.load ||
            previous.snapshot != current.snapshot,
        builder: _body,
      ),
    ),
  );

  Widget _body(BuildContext context, PayrollState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    switch (state.load) {
      case PayrollLoad.failure:
        return StaffResultsErrorState(
          failure: state.failure,
          onRetry: cubit.load,
        );
      case PayrollLoad.loading:
        return const EteeloListSkeleton(rowCount: 8);
      case PayrollLoad.ready:
        break;
    }
    final currentMonth = state.today.substring(0, 7);
    final all = PayrollArrears.of(state.snapshot, currentMonth: currentMonth);
    final needle = _search.trim();
    bool matches(PayrollArrearsAgent agent) {
      if (needle.isEmpty) return true;
      final member = state.snapshot.member(agent.staffMemberId);
      return member != null && StaffMemberSearch.matches(member, needle);
    }

    final visible = [
      for (final agent in all)
        if (_filter.keeps(agent) && matches(agent)) agent,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollArrearsTiles(agents: all, currentMonth: currentMonth),
        const SizedBox(height: AppSpacing.lg),
        StaffSearchToolbar(
          text: _search,
          label: l10n.payrollSearchHint,
          placeholder: l10n.payrollSearchHint,
          onTextChanged: (text) => setState(() => _search = text),
        ),
        const SizedBox(height: AppSpacing.sm),
        PayrollChoiceChips<PayrollArrearsFilter>(
          values: PayrollArrearsFilter.values,
          selected: _filter,
          label: (filter) => switch (filter) {
            PayrollArrearsFilter.all => l10n.payrollFilterAll,
            PayrollArrearsFilter.deferred => l10n.payrollArrearsFilterDeferred,
            PayrollArrearsFilter.unpaid => l10n.payrollArrearsFilterUnpaid,
            PayrollArrearsFilter.prioritized =>
              l10n.payrollArrearsFilterPriority,
          },
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: AppSpacing.md),
        if (all.isEmpty)
          EteeloEmptyResult(
            label: l10n.payrollArrearsEmpty,
            medallionIcon: Icons.task_alt,
          )
        else if (visible.isEmpty)
          EteeloEmptyResult(
            label: l10n.payrollEmptyFilter,
            medallionIcon: Icons.filter_alt_off_outlined,
            primaryAction: EteeloButton.secondary(
              label: l10n.payrollShowAll,
              onPressed: () => setState(() {
                _filter = PayrollArrearsFilter.all;
                _search = '';
              }),
              fullWidth: false,
            ),
          )
        else
          PayrollArrearsTable(
            snapshot: state.snapshot,
            agents: visible,
            currentMonth: currentMonth,
            onOpen: (agent) => _open(context, state, agent, currentMonth),
          ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    PayrollState state,
    PayrollArrearsAgent agent,
    String currentMonth,
  ) async {
    final cubit = context.read<PayrollCubit>();
    final name =
        state.snapshot.member(agent.staffMemberId)?.fullName ??
        agent.staffMemberId;
    final outcome = await PayrollArrearsAgentDialog.show(
      context,
      PayrollArrearsAgentDialog(
        name: name,
        snapshot: state.snapshot,
        agent: agent,
        currentMonth: currentMonth,
        canWrite: PermissionGate.allows(context, kPayrollWriteAccess.requires),
        profile:
            state.snapshot.profiles[agent.staffMemberId] ??
            StaffPayProfile.empty(agent.staffMemberId),
      ),
    );
    if (outcome == null || !context.mounted) return;
    final prioritize = outcome.prioritize;
    if (prioritize != null) {
      for (final arrear in agent.months) {
        if (arrear.prioritized == prioritize) continue;
        await cubit.perform(
          (commands) =>
              commands.setArrearsPriority(arrear, prioritized: prioritize),
        );
        if (!context.mounted) return;
      }
      return;
    }
    final proof = outcome.proof;
    if (proof == null) return;
    // Le registre a pu bouger pendant la saisie (un pull, un autre poste) :
    // la répartition se refait sur l'agent tel qu'il est maintenant.
    final snapshot = cubit.state.snapshot;
    final fresh = PayrollArrears.of(
      snapshot,
      currentMonth: currentMonth,
    ).where((a) => a.staffMemberId == agent.staffMemberId).firstOrNull;
    if (fresh == null) return;
    await cubit.perform(
      (commands) => commands.payArrears(
        snapshot,
        fresh,
        currency: outcome.currency,
        amountInCents: outcome.amountInCents,
        proof: proof,
        name: name,
      ),
    );
  }
}
