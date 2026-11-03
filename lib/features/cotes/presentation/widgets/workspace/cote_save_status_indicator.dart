import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'état de l'enregistrement. Seuls « enregistré » et « échec » s'annoncent au
/// lecteur d'écran : le reste passerait à chaque frappe.
class CoteSaveStatusIndicator extends StatelessWidget {
  final CoteSaveStatus status;
  final VoidCallback onRetry;

  const CoteSaveStatusIndicator({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (IconData icon, Color color, String label) = switch (status) {
      CoteSaveIdle() => (
        Icons.edit_outlined,
        AppColors.textMuted,
        l10n.coteSaveIdle,
      ),
      CoteSaving() => (
        Icons.edit_outlined,
        AppColors.textMuted,
        l10n.coteSaving,
      ),
      CoteSaved(:final atMs) => (
        Icons.check_rounded,
        AppColors.vertSavane,
        l10n.coteSavedAt(_time(context, atMs)),
      ),
      CoteSaveOffline(:final pending) => (
        Icons.cloud_off_outlined,
        AppColors.warningInk,
        l10n.coteSaveOffline(pending),
      ),
      CoteSaveFailed(:final sessionExpired) => (
        Icons.error_outline_rounded,
        AppColors.error,
        sessionExpired ? l10n.coteSaveSessionExpired : l10n.coteSaveFailed,
      ),
    };
    final failed = status is CoteSaveFailed;
    final announced = failed || status is CoteSaved;
    final retryable = failed && !(status as CoteSaveFailed).sessionExpired;
    return Semantics(
      liveRegion: announced,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.coteInlineIconSize, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
          if (retryable)
            TextButton(onPressed: onRetry, child: Text(l10n.coteSaveRetry)),
        ],
      ),
    );
  }

  String _time(BuildContext context, int atMs) {
    final at = DateTime.fromMillisecondsSinceEpoch(atMs);
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true);
  }
}
