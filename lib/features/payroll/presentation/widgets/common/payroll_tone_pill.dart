import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';

/// Un libellé court sur le voile de son sens : règlement d'un salaire,
/// statut d'une avance, étape d'une demande.
class PayrollTonePill extends StatelessWidget {
  final String label;
  final PayrollTone tone;

  const PayrollTonePill({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(color: tone.soft, borderRadius: AppRadius.brPill),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(color: tone.ink),
    ),
  );
}
