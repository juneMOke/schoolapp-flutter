import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/buttons/stepper_actions_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pied fixe du stepper d'inscription (PARCOURS 21) : navigation à gauche,
/// indicateur d'état au centre, actions à droite. Le pied est ancré hors du
/// défilement pour toutes les étapes. L'indicateur est masqué pour le résumé
/// et pour l'étape Frais (lecture seule, sans enregistrement).
class EnrollmentStepperControls extends StatelessWidget {
  final int currentStep;
  final bool isLast;
  final bool isSummaryStep;
  final bool dirty;
  final bool valid;
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
    required this.dirty,
    required this.valid,
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
    final showIndicator = !isSummaryStep && showSaveAction;

    final actionsBar = StepperActionsBar(
      leadingActionBuilder: currentStep > 0
          ? (_) => SecondaryButton(
              label: l10n.previous,
              icon: Icons.arrow_back_rounded,
              onPressed: onPrevious,
              fullWidth: false,
            )
          : null,
      centerBuilder: showIndicator
          ? (_) => _SaveStatusIndicator(status: _status)
          : null,
      trailingActionBuilders: <WidgetBuilder>[
        if (showSaveAction)
          (_) => SecondaryButton(
            label: saveLabel,
            icon: Icons.save_outlined,
            onPressed: canSave ? onSave : null,
            isLoading: savingNow,
            fullWidth: false,
          ),
        // Au dernier step, le bouton « Valider l'inscription » (Save) remplace
        // le bouton « Terminer » — on ne l'affiche donc pas en doublon.
        if (!(isLast && showSaveAction))
          (_) => PrimaryButton(
            label: isLast ? l10n.finish : l10n.next,
            icon: isLast
                ? Icons.check_circle_outline
                : Icons.arrow_forward_rounded,
            onPressed: canContinue ? onContinue : null,
            fullWidth: false,
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: actionsBar),
    );
  }

  _SaveUiStatus get _status {
    if (savingNow) {
      return _SaveUiStatus.saving;
    }
    if (dirty && valid) {
      return _SaveUiStatus.pending;
    }
    if (dirty && !valid) {
      return _SaveUiStatus.incomplete;
    }
    if (!dirty && valid) {
      return _SaveUiStatus.saved;
    }
    return _SaveUiStatus.idle;
  }
}

class _SaveStatusIndicator extends StatelessWidget {
  final _SaveUiStatus status;

  const _SaveStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == _SaveUiStatus.saving)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            status.message(l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

enum _SaveUiStatus { idle, incomplete, pending, saving, saved }

extension _SaveUiStatusX on _SaveUiStatus {
  Color get color => switch (this) {
    _SaveUiStatus.idle => AppColors.textMuted,
    _SaveUiStatus.incomplete => AppColors.textSecondary,
    _SaveUiStatus.pending => AppColors.warning,
    _SaveUiStatus.saving => AppColors.info,
    _SaveUiStatus.saved => AppColors.success,
  };

  String message(AppLocalizations l10n) => switch (this) {
    _SaveUiStatus.idle => l10n.stepSaveStateIdle,
    _SaveUiStatus.incomplete => l10n.stepSaveStateIncomplete,
    _SaveUiStatus.pending => l10n.stepSaveStatePending,
    _SaveUiStatus.saving => l10n.stepSaveStateSaving,
    _SaveUiStatus.saved => l10n.stepSaveStateSaved,
  };
}
