import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/stepper_actions_bar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pied fixe du stepper d'inscription (PARCOURS 21) : fine bande sur une seule
/// ligne — navigation à gauche, indicateur d'état au centre, actions à droite.
/// L'indicateur est masqué pour le résumé et pour l'étape Frais (lecture seule).
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Téléphone : barre ultra-compacte en icônes seules (évite l'overflow
            // des 3 boutons label+icône + indicateur sur une seule ligne).
            final compact =
                constraints.maxWidth < AppBreakpoints.stepperControlsCompactMax;
            return compact ? _buildCompactBar(l10n) : _buildRegularBar(l10n);
          },
        ),
      ),
    );
  }

  /// Barre large : navigation à gauche, indicateur au centre, actions à droite,
  /// boutons avec labels (comportement d'origine).
  Widget _buildRegularBar(AppLocalizations l10n) {
    final showIndicator = !isSummaryStep && showSaveAction;

    return StepperActionsBar(
      leadingActionBuilder: currentStep > 0
          ? (_) => EteeloButton.secondary(
              label: l10n.previous,
              icon: Icons.arrow_back_rounded,
              onPressed: onPrevious,
              size: EteeloButtonSize.compact,
              fullWidth: false,
            )
          : null,
      centerBuilder: showIndicator
          ? (_) => _SaveStatusIndicator(status: _status)
          : null,
      trailingActionBuilders: <WidgetBuilder>[
        if (showSaveAction)
          // Au dernier step, « Enregistrer » porte l'action Valider l'inscription :
          // bouton PRIMAIRE + icône check (proéminent). Sur les étapes
          // intermédiaires, save reste secondaire (disquette).
          (_) => isLast
              ? EteeloButton.primary(
                  label: saveLabel,
                  icon: Icons.check_circle_outline,
                  onPressed: canSave ? onSave : null,
                  isLoading: savingNow,
                  size: EteeloButtonSize.compact,
                  fullWidth: false,
                )
              : EteeloButton.secondary(
                  label: saveLabel,
                  icon: Icons.save_outlined,
                  onPressed: canSave ? onSave : null,
                  isLoading: savingNow,
                  size: EteeloButtonSize.compact,
                  fullWidth: false,
                ),
        // Au dernier step, le bouton Valider (Save) remplace « Terminer » — on
        // ne l'affiche donc pas en doublon.
        if (!(isLast && showSaveAction))
          (_) => EteeloButton.primary(
            label: isLast ? l10n.finish : l10n.next,
            icon: isLast
                ? Icons.check_circle_outline
                : Icons.arrow_forward_rounded,
            onPressed: canContinue ? onContinue : null,
            size: EteeloButtonSize.compact,
            fullWidth: false,
          ),
      ],
    );
  }

  /// Barre compacte (téléphone) : Précédent / Enregistrer / Suivant en icônes
  /// seules (tooltips pour l'accessibilité), l'indicateur d'état est masqué.
  Widget _buildCompactBar(AppLocalizations l10n) {
    final buttons = <Widget>[
      if (currentStep > 0)
        _StepperNavButton(
          icon: Icons.arrow_back_rounded,
          tooltip: l10n.previous,
          onPressed: onPrevious,
        ),
      if (showSaveAction)
        _StepperNavButton(
          // Au dernier step, « Enregistrer » porte l'action Valider l'inscription :
          // icône check PRIMAIRE (terre cuite plein) pour la rendre proéminente.
          // Sur les étapes intermédiaires, save reste secondaire (disquette).
          icon: isLast ? Icons.check_circle_outline : Icons.save_outlined,
          tooltip: saveLabel,
          onPressed: canSave ? onSave : null,
          isLoading: savingNow,
          primary: isLast,
        ),
      if (!(isLast && showSaveAction))
        _StepperNavButton(
          icon: isLast
              ? Icons.check_circle_outline
              : Icons.arrow_forward_rounded,
          tooltip: isLast ? l10n.finish : l10n.next,
          onPressed: canContinue ? onContinue : null,
          primary: true,
        ),
    ];

    return Row(
      // Un seul bouton (ex. Suivant seul) → ancré à droite (action primaire) ;
      // sinon réparti (Précédent à gauche, Suivant à droite).
      mainAxisAlignment: buttons.length == 1
          ? MainAxisAlignment.end
          : MainAxisAlignment.spaceBetween,
      children: buttons,
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

/// Bouton-icône compact du pied mobile (icône seule + tooltip). `primary` =
/// plein terre cuite (action suivante), sinon bordé bleu ardoise (Précédent /
/// Enregistrer). Gère états désactivé et chargement.
class _StepperNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;
  final bool isLoading;

  const _StepperNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final Color background;
    final Color foreground;
    final ShapeBorder shape;
    if (primary) {
      background = enabled ? AppColors.terreCuite : AppColors.stateDisabled;
      foreground = enabled ? AppColors.blancCasse : AppColors.textMuted;
      shape = const CircleBorder();
    } else {
      background = AppColors.surface;
      foreground = enabled ? AppColors.bleuArdoise : AppColors.textMuted;
      shape = CircleBorder(
        side: BorderSide(
          color: enabled ? AppColors.bleuArdoise : AppColors.stateDisabled,
          width: 1.5,
        ),
      );
    }

    final content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Icon(icon, size: 20, color: foreground);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: Material(
          color: background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: AppDimensions.minTouchTarget,
              height: AppDimensions.minTouchTarget,
              child: Center(child: content),
            ),
          ),
        ),
      ),
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
