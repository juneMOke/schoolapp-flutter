import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le statut affiché d'une paie. Un geste en vol se lit en pointillé : il
/// n'est pas encore l'état du serveur.
class PayrollStatusPill extends StatelessWidget {
  final PayrollPhase phase;

  const PayrollStatusPill({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final tone = PayrollTone.of(phase);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: phase.inFlight ? tone.color : tone.soft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            phase.inFlight ? Icons.cloud_upload_outlined : Icons.circle,
            size: phase.inFlight ? AppSpacing.md : AppSpacing.sm,
            color: tone.color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              PayrollLabels.phase(AppLocalizations.of(context)!, phase),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(color: tone.ink),
            ),
          ),
        ],
      ),
    );
  }
}
