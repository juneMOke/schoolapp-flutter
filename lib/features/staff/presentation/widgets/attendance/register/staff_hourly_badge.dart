import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le badge « VAC · H » d'un vacataire payé à l'heure, à droite de l'agent.
class StaffHourlyBadge extends StatelessWidget {
  const StaffHourlyBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: const BoxDecoration(
      color: AppColors.staffVacataireSoft,
      borderRadius: AppRadius.brPill,
    ),
    child: Text(
      AppLocalizations.of(context)!.staffAttendanceHourlyBadge,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.staffVacataireInk,
      ),
    ),
  );
}
