import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/helpers/justification_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La pastille d'état d'une justification : en attente, en cours d'envoi,
/// acceptée, refusée.
class JustificationStatusTag extends StatelessWidget {
  final AttendanceJustification justification;

  const JustificationStatusTag({super.key, required this.justification});

  @override
  Widget build(BuildContext context) {
    final tone = JustificationLabels.tone(justification);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        border: Border.all(color: tone.border),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        JustificationLabels.status(
          AppLocalizations.of(context)!,
          justification,
        ),
        style: AppTypography.labelSmall.copyWith(color: tone.ink),
      ),
    );
  }
}
