import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepperControls extends StatelessWidget {
  final int currentStep;
  final bool isLast;
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

    return Row(
      children: [
        if (currentStep > 0)
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(l10n.previous),
          ),
        const Spacer(),
        if (showSaveAction) ...[
          FilledButton.icon(
            onPressed: canSave ? onSave : null,
            icon: savingNow
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(saveLabel),
            style: FilledButton.styleFrom(
              backgroundColor: canSave ? const Color(0xFF0EA5E9) : null,
              foregroundColor: Colors.white,
              elevation: canSave ? 6 : 0,
              shadowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        ElevatedButton.icon(
          onPressed: canContinue ? onContinue : null,
          icon: Icon(
            isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
            size: 16,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          label: Text(isLast ? l10n.finish : l10n.next),
        ),
      ],
    );
  }
}