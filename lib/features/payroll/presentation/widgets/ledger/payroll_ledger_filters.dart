import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Puces de contrat, versés / à verser une fois la paie verrouillée, et la
/// recherche d'un agent.
class PayrollLedgerFilters extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerFilters({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final locked = state.view?.phase.isLocked ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffSearchToolbar(
          text: state.search,
          label: l10n.payrollSearchHint,
          placeholder: l10n.payrollSearchHint,
          onTextChanged: cubit.setSearch,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final kind in StaffContractKind.values)
              _contractChip(context, kind, cubit),
            if (locked)
              PayrollChoiceChips<PayrollPayFilter>(
                values: PayrollPayFilter.values,
                selected: state.payFilter,
                label: (filter) => switch (filter) {
                  PayrollPayFilter.all => l10n.payrollFilterAll,
                  PayrollPayFilter.toPay => l10n.payrollFilterToPay,
                  PayrollPayFilter.paid => l10n.payrollFilterPaid,
                },
                onSelected: cubit.setPayFilter,
              ),
          ],
        ),
      ],
    );
  }

  Widget _contractChip(
    BuildContext context,
    StaffContractKind kind,
    PayrollCubit cubit,
  ) {
    final tone = StaffContractTone.of(kind);
    return StaffFilterChip(
      label: StaffLabels.contract(AppLocalizations.of(context)!, kind),
      selected: state.contractFilter == kind,
      color: tone.color,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => cubit.toggleContract(kind),
    );
  }
}
