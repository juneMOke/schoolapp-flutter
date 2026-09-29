import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_address_step.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_diplomas_step.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_identity_step.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_job_step.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_notice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contenu de l'étape courante, défilant, précédé — après une tentative —
/// du nombre de champs à corriger.
class StaffAgentBody extends StatelessWidget {
  final StaffAgentState state;
  final AddressGeoCatalog? catalog;
  final String today;
  final ValueChanged<StaffMemberDraft Function(StaffMemberDraft)> onChanged;

  /// Ce qui suit une étape hors saisie, par étape : les contrats sous
  /// « Poste », les pièces sous « Diplômes » — des gestes à part, pas des
  /// champs de la fiche.
  final Map<int, Widget> appendices;

  const StaffAgentBody({
    super.key,
    required this.state,
    required this.catalog,
    required this.today,
    required this.onChanged,
    this.appendices = const {},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepErrors = state.visibleErrors.keys
        .where((field) => field.step == state.step)
        .length;
    final step = switch (state.step) {
      0 => StaffIdentityStep(state: state, onChanged: onChanged),
      1 => StaffAddressStep(
        state: state,
        catalog: catalog,
        onChanged: onChanged,
      ),
      2 => StaffJobStep(state: state, today: today, onChanged: onChanged),
      _ => StaffDiplomasStep(state: state, onChanged: onChanged),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.staffAgentBodyMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stepErrors > 0)
                StaffNotice.error(l10n.staffErrorsToFix(stepErrors)),
              KeyedSubtree(
                key: ValueKey('staff-step-${state.step}'),
                child: step,
              ),
              if (appendices[state.step] case final appendix?) ...[
                const SizedBox(height: AppSpacing.lg),
                appendix,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
