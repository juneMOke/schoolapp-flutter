import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pastille discrète « en attente de synchro » — posée sur une créance dont le
/// reste inclut un encaissement de ce poste non remonté, ou sur un paiement
/// `PENDING_SYNC` (FRONT §3/§5). Purement informatif (non bloquant).
class FinancePendingSyncBadge extends StatelessWidget {
  const FinancePendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_outlined, size: 13, color: AppColors.textMuted),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            l10n.financePendingSyncBadge,
            style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
