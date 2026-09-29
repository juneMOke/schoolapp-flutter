import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où est la donnée : une pastille de couleur et son libellé. Orange sur la
/// tablette, vert au serveur, rouge refusée.
class StaffSyncPill extends StatelessWidget {
  final StaffSyncState state;

  const StaffSyncPill({super.key, required this.state});

  static Color colorOf(StaffSyncState state) => switch (state) {
    StaffSyncState.synced => AppColors.success,
    StaffSyncState.pending => AppColors.warning,
    StaffSyncState.failed => AppColors.error,
  };

  /// Encre du libellé : le [AppColors.warning] fonde la pastille mais ne
  /// s'écrit pas sur blanc.
  static Color inkOf(StaffSyncState state) => switch (state) {
    StaffSyncState.synced => AppColors.success,
    StaffSyncState.pending => AppColors.staffPartialInk,
    StaffSyncState.failed => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StaffSyncDot(state: state),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            StaffLabels.sync(l10n, state),
            style: AppTypography.labelSmall.copyWith(color: inkOf(state)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// La seule pastille, sans libellé — posée sur l'avatar.
class StaffSyncDot extends StatelessWidget {
  final StaffSyncState state;
  final double size;

  const StaffSyncDot({super.key, required this.state, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: StaffSyncPill.colorOf(state),
      shape: BoxShape.circle,
    ),
  );
}
