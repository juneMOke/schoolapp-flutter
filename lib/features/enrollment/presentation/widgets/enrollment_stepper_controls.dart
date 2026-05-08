import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/buttons/stepper_actions_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepperControls extends StatelessWidget {
  final int currentStep;
  final bool isLast;
  final bool isSummaryStep;
  final bool canSave;
  final bool canContinue;
  final bool showSaveAction;
  final bool savingNow;
  final String saveLabel;
  final VoidCallback onPrevious;
  final VoidCallback onSave;
  final VoidCallback onContinue;

  const EnrollmentStepperControls({
    super.key,
    required this.currentStep,
    required this.isLast,
    required this.isSummaryStep,
    required this.canSave,
    required this.canContinue,
    required this.showSaveAction,
    required this.savingNow,
    required this.saveLabel,
    required this.onPrevious,
    required this.onSave,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trailingActionBuilders = <WidgetBuilder>[
      if (showSaveAction)
        (_) => SecondaryButton(
          label: saveLabel,
          icon: Icons.save_outlined,
          onPressed: canSave ? onSave : null,
          isLoading: savingNow,
          fullWidth: false,
        ),
      // Au dernier step, le bouton "Valider l'inscription" (Save) remplace
      // le bouton "Terminer" — on ne l'affiche donc pas en doublon.
      if (!(isLast && showSaveAction))
        (_) => PrimaryButton(
          label: isLast ? l10n.finish : l10n.next,
          icon: isLast
              ? Icons.check_circle_outline
              : Icons.arrow_forward_rounded,
          onPressed: canContinue ? onContinue : null,
          fullWidth: false,
        ),
    ];

    final actionsBar = StepperActionsBar(
      leadingActionBuilder: currentStep > 0
          ? (_) => SecondaryButton(
              label: l10n.previous,
              icon: Icons.arrow_back_rounded,
              onPressed: onPrevious,
              fullWidth: false,
            )
          : null,
      trailingActionBuilders: trailingActionBuilders,
    );

    if (!isSummaryStep) {
      return actionsBar;
    }

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: actionsBar),
    );
  }
}
