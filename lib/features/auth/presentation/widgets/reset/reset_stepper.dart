import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Diamètre d'un point d'étape (passé/à venir).
const double _dotSize = 10;

/// Diamètre de l'anneau de l'étape courante (point bleu + anneau or).
const double _currentRingSize = 20;

/// Épaisseur des connecteurs reliant les points.
const double _connectorHeight = 3;

/// Indicateur de progression visuel du flux de réinitialisation (3 étapes).
///
/// Purement décoratif ([ExcludeSemantics]) : l'information textuelle « Étape X
/// sur N » est portée par le live region de `ResetStepperHeader`. [currentStep]
/// est 1-based. États : passé (or plein), courant (bleu profond + anneau or),
/// à venir (contour). Connecteur or si l'étape précédente est franchie.
class ResetStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ResetStepper({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var step = 1; step <= totalSteps; step++) {
      children.add(_Dot(step: step, currentStep: currentStep));
      if (step < totalSteps) {
        children.add(_Connector(filled: step < currentStep));
      }
    }

    return ExcludeSemantics(
      child: SizedBox(
        height: _currentRingSize,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int step;
  final int currentStep;

  const _Dot({required this.step, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    if (step == currentStep) {
      return Container(
        width: _currentRingSize,
        height: _currentRingSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.orDoux, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bleuProfond,
            ),
          ),
        ),
      );
    }

    final isDone = step < currentStep;
    return Container(
      width: _dotSize,
      height: _dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? AppColors.orDoux : Colors.transparent,
        border: isDone ? null : Border.all(color: AppColors.borderStrong),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool filled;

  const _Connector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: _connectorHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.orDoux : AppColors.border,
          borderRadius: AppRadius.brPill,
        ),
      ),
    );
  }
}
