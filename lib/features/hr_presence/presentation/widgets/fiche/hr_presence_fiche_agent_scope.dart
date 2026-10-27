import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_picker.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_scope_bar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_sheet_button.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La portée de la fiche d'un agent — mensuelle ou annuelle, le mois au
/// sélecteur — et, au bout, le choix d'un autre agent. Dans sa carte tant que
/// la fiche charge ou échoue ; nue dans la feuille une fois les données là.
class HrPresenceFicheAgentScope extends StatelessWidget {
  final HrPresenceFicheState state;
  final HrPresenceFicheCubit cubit;
  final bool framed;

  const HrPresenceFicheAgentScope({
    super.key,
    required this.state,
    required this.cubit,
    required this.framed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = state.members;
    return HrPresenceScopeBar(
      framed: framed,
      yearly: state.yearly,
      onYearly: (yearly) => unawaited(cubit.setYearly(yearly)),
      month: state.month,
      isCurrentMonth: state.isCurrentMonth,
      onPrevious: state.canStepBack
          ? () => unawaited(cubit.stepMonth(-1))
          : null,
      onNext: () => unawaited(cubit.stepMonth(1)),
      onCurrent: () => unawaited(cubit.goCurrentMonth()),
      onPickMonth: () async {
        final picked = await pickPresenceMonth(
          context,
          month: state.month,
          firstMonth: state.firstMonth,
          lastMonth: state.currentMonth,
        );
        if (picked != null && !cubit.isClosed) {
          unawaited(cubit.openMonth(picked));
        }
      },
      yearLabel: state.yearData?.schoolYear?.name,
      // Le choix d'un autre agent, et la fiche en PDF.
      trailing: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
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
          HrPresenceSheetButton(state: state),
        ],
      ),
    );
  }
}
