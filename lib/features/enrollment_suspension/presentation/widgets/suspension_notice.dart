import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// L'encart d'une modale de désactivation : ce que le geste retire, ce qu'il
/// garde — c'est lui qui évite qu'on prenne la désactivation pour une
/// radiation. [lead] s'écrit en gras.
class SuspensionNotice extends StatelessWidget {
  final String? lead;
  final String body;

  const SuspensionNotice({super.key, this.lead, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.stateHover,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.bleuArdoiseSoft),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.bleuArdoise),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (lead != null)
                  TextSpan(
                    text: '$lead ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: body),
              ],
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// L'échec d'un geste, sous les champs : rien n'a été modifié, la saisie
/// reste là pour un nouvel essai.
class SuspensionGestureError extends StatelessWidget {
  final String message;

  const SuspensionGestureError({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    ),
  );
}
