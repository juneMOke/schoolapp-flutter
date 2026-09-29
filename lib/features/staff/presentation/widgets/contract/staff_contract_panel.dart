import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_state.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_contract_form_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les contrats d'un agent enregistré, sous l'étape « Poste » : la frise, les
/// montants pour qui les lit, et les gestes pour qui peut les faire.
///
/// Un geste ne passe jamais par la fiche : il s'écrit à part, puis la fiche
/// est relue pour que sa frise le montre.
class StaffContractPanel extends StatelessWidget {
  final StaffMember member;
  final String today;

  const StaffContractPanel({
    super.key,
    required this.member,
    required this.today,
  });

  Future<void> _add(BuildContext context) async {
    final contracts = context.read<StaffContractsCubit>();
    final agent = context.read<StaffAgentCubit>();
    final result = await StaffContractFormPage.open(
      context,
      initial: StaffContractDraft(effectiveFrom: today),
    );
    if (result is! StaffContractSubmitted) return;
    if (await contracts.add(member.id, result.draft)) {
      await agent.refreshMember();
    }
  }

  Future<void> _correct(BuildContext context, StaffContract original) async {
    final contracts = context.read<StaffContractsCubit>();
    final agent = context.read<StaffAgentCubit>();
    final result = await StaffContractFormPage.open(
      context,
      initial: StaffContractDraft.of(
        original,
        amountText: AmountInput.fromCents,
      ),
      correcting: true,
    );
    final written = switch (result) {
      StaffContractSubmitted(:final draft) => await contracts.correct(
        original,
        reason: draft.reason,
        replacement: draft,
      ),
      StaffContractCancelledOnly(:final reason) => await contracts.correct(
        original,
        reason: reason,
      ),
      null => false,
    };
    if (written) await agent.refreshMember();
  }

  /// La frise de la fiche, la plus récente d'abord, suivie des poses que le
  /// serveur a refusées : hors frise car en vigueur nulle part, mais à
  /// montrer avec leur refus.
  List<StaffContractPeriod> _timeline(List<StaffContract> details) {
    final known = {for (final period in member.contracts) period.contractId};
    return [
      ...[...member.contracts]
        ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom)),
      for (final contract in details)
        if (contract.syncState == StaffSyncState.failed &&
            !contract.isCorrected &&
            !known.contains(contract.id))
          contract.asPeriod,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRead = PermissionGate.allows(context, const [Perm.hrPayRead]);
    final canWrite = PermissionGate.allows(context, const [Perm.hrPayWrite]);
    return BlocConsumer<StaffContractsCubit, StaffContractsState>(
      listenWhen: (previous, current) =>
          current.outcomeSeq != previous.outcomeSeq,
      listener: (context, state) {
        switch (state.outcome) {
          case StaffContractOutcome.saved:
            AppSnackBar.showSuccess(context, l10n.staffContractSaved);
          case StaffContractOutcome.failed:
            AppSnackBar.showError(context, l10n.staffContractSaveFailed);
          case null:
            break;
        }
      },
      builder: (context, state) => StaffContractSection(
        timeline: _timeline(canRead ? state.contracts : const []),
        current: StaffContractTimeline.currentAt(member.contracts, today),
        details: canRead ? state.byId : const {},
        onAdd: canWrite && !state.writing
            ? () => unawaited(_add(context))
            : null,
        onCorrect: canWrite && canRead && !state.writing
            ? (contract) => unawaited(_correct(context, contract))
            : null,
      ),
    );
  }
}
