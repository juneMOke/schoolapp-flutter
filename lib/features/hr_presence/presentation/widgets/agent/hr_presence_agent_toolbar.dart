import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Passer d'un agent à l'autre sans revenir, et d'un mois à l'autre — jamais
/// au-delà du mois en cours, ni avant la rentrée.
class HrPresenceAgentToolbar extends StatelessWidget {
  final HrPresenceAgentMonthState state;

  const HrPresenceAgentToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceAgentMonthCubit>();
    final members = state.members;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        // Le fichier local n'est pas encore lu (ou vide) : pas de sélecteur.
        if (members.isNotEmpty)
          PresencePersonPicker<StaffMember>(
            entries: [
              for (final m in members)
                PresencePickerEntry(
                  value: m,
                  id: m.id,
                  firstName: m.firstName,
                  lastName: m.lastName,
                  fullName: m.fullName,
                  detail: m.jobTitle,
                ),
            ],
            selectedId: state.agentId,
            label: l10n.staffAttendanceTabAgent,
            placeholder: l10n.staffAttendanceAgentPicker,
            matches: StaffMemberSearch.matches,
            onSelected: (picked) => unawaited(cubit.openAgent(picked.id)),
          ),
        PresenceMonthNav(
          month: state.month,
          isCurrent: state.isCurrentMonth,
          onPrevious: state.canStepBack
              ? () => unawaited(cubit.stepMonth(-1))
              : null,
          onNext: () => unawaited(cubit.stepMonth(1)),
          onCurrent: () => unawaited(cubit.goCurrentMonth()),
        ),
      ],
    );
  }
}
