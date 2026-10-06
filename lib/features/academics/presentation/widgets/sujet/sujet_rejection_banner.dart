import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet_codes.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le serveur a refusé le sujet : le brouillon reste, avec ce qu'il faut
/// faire. `MAX_LOCKED` propose de le renvoyer sans toucher au maximum.
class SujetRejectionBanner extends StatelessWidget {
  final String? code;
  final VoidCallback onResendWithoutMax;

  const SujetRejectionBanner({
    super.key,
    required this.code,
    required this.onResendWithoutMax,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxLocked = code == EvaluationSujetCodes.maxLocked;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.academicsScoreFailSoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.academicsScoreFail.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: AppDimensions.sujetIconSize,
            color: AppColors.academicsScoreFail,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (code) {
                    EvaluationSujetCodes.maxLocked =>
                      l10n.sujetRejectedMaxLocked,
                    EvaluationSujetCodes.questionMismatch =>
                      l10n.sujetRejectedQuestionMismatch,
                    EvaluationSujetCodes.sujetEmpty =>
                      l10n.sujetRejectedEmptyPublished,
                    _ => l10n.sujetRejectedGeneric,
                  },
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.academicsScoreFail,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (maxLocked)
                  PermissionGate(
                    requires: const [Perm.academicsGradeWrite],
                    child: SessionWriteGate(
                      child: TextButton(
                        onPressed: onResendWithoutMax,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.bleuArdoise,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(l10n.sujetResendWithoutMax),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
