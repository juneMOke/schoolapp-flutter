import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une ligne d'avertissement dans une carte : pourquoi accepter n'est plus
/// possible, ou pourquoi la dernière décision n'est pas passée.
class JustificationCardNotice extends StatelessWidget {
  final String message;

  const JustificationCardNotice({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.presenceMarkLateSoft,
      border: Border.all(color: AppColors.presenceMarkLateBorder),
      borderRadius: AppRadius.brSm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: AppSpacing.lg,
          color: AppColors.presenceMarkLateInk,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.presenceMarkLateInk,
            ),
          ),
        ),
      ],
    ),
  );
}
