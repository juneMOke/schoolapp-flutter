import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied de la page agent, selon le mode : Précédent / Suivant /
/// Enregistrer l'agent en création, Annuler / Enregistrer en modification,
/// rien en consultation.
class StaffAgentFooter extends StatelessWidget {
  final StaffAgentState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const StaffAgentFooter({
    super.key,
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (state.mode == StaffAgentMode.view) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final create = state.mode == StaffAgentMode.create;
    final actions = <Widget>[
      if (create && state.step > 0)
        EteeloButton.secondary(
          label: l10n.staffActionPrevious,
          icon: Icons.arrow_back,
          onPressed: onPrevious,
          fullWidth: false,
        ),
      if (!create)
        EteeloButton.secondary(
          label: l10n.staffActionCancel,
          onPressed: onCancel,
          fullWidth: false,
        ),
      const Spacer(),
      if (create && !state.isLastStep)
        EteeloButton.primary(
          label: l10n.staffActionNext,
          icon: Icons.arrow_forward,
          onPressed: onNext,
          fullWidth: false,
        )
      else
        EteeloButton.primary(
          label: create ? l10n.staffActionCreate : l10n.staffActionSave,
          icon: Icons.check,
          isLoading: state.saving,
          onPressed: state.saving ? null : onSave,
          fullWidth: false,
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: Row(children: actions)),
    );
  }
}
