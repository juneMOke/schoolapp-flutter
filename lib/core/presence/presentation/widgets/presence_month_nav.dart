import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// ‹ septembre 2026 › — partagé par la fiche mensuelle et le récapitulatif ;
/// jamais au-delà du mois en cours.
class PresenceMonthNav extends StatelessWidget {
  /// `YYYY-MM`.
  final String month;
  final bool isCurrent;

  /// `null` : début de l'année scolaire.
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  const PresenceMonthNav({
    super.key,
    required this.month,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget arrow(IconData icon, String tooltip, VoidCallback? onPressed) =>
        SizedBox.square(
          dimension: AppDimensions.presenceMarkTapTarget,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        arrow(
          Icons.chevron_left,
          l10n.presenceMarkPreviousMonth,
          onPrevious,
        ),
        Text(
          PresenceLabels.month(MaterialLocalizations.of(context), month),
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        arrow(
          Icons.chevron_right,
          l10n.presenceMarkNextMonth,
          isCurrent ? null : onNext,
        ),
        if (!isCurrent)
          TextButton(
            onPressed: onCurrent,
            child: Text(l10n.presenceMarkCurrentMonth),
          ),
      ],
    );
  }
}
