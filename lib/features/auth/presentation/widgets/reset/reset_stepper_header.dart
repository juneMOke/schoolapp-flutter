import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/auth/auth_form_header.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Nombre total d'étapes du flux de réinitialisation (e-mail → code → mdp).
const int _totalResetSteps = 3;

/// En-tête à indicateur de progression du flux de réinitialisation.
///
/// Mappe l'étape courante (1-based) à son titre/sous-texte/libellé, puis délègue
/// le rendu à [AuthFormHeader] (eyebrow + titre Lora + sous-texte) en injectant
/// le [ResetStepper] et la ligne « Étape X sur N · libellé » dans le slot
/// stepper. La ligne est annoncée une fois au changement d'étape (live region).
class ResetStepperHeader extends StatelessWidget {
  final int currentStep;

  const ResetStepperHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (
      String title,
      String subtitle,
      String stepLabel,
    ) = switch (currentStep) {
      1 => (
        l10n.forgotPasswordTitle,
        l10n.enterEmailToReceiveOtp,
        l10n.resetStepLabelEmail,
      ),
      2 => (
        l10n.otpValidation,
        l10n.enterSixDigitCode,
        l10n.resetStepLabelCode,
      ),
      _ => (
        l10n.newPassword,
        l10n.chooseNewPassword,
        l10n.resetStepLabelPassword,
      ),
    };

    final indicator = l10n.resetStepIndicator(
      currentStep,
      _totalResetSteps,
      stepLabel,
    );

    return AuthFormHeader(
      eyebrow: l10n.resetEyebrow,
      title: title,
      subtitle: subtitle,
      stepper: Semantics(
        container: true,
        liveRegion: true,
        label: indicator,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResetStepper(
                currentStep: currentStep,
                totalSteps: _totalResetSteps,
              ),
              const SizedBox(height: 10),
              Text(
                indicator,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
