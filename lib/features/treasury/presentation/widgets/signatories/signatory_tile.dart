import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un bloc de signature tel que le rapport l'imprime : la légende, le nom (ou
/// le blanc à remplir à la main), la fonction.
class SignatoryTile extends StatelessWidget {
  final ReportSignatory signatory;

  const SignatoryTile({super.key, required this.signatory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = signatory.name?.trim();
    final blank = name == null || name.isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            signatory.caption,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            blank ? l10n.treasurySignatoryBlank : name,
            style: blank
                ? AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  )
                : AppTypography.titleSmall,
          ),
          Text(
            signatory.function,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (signatory.filledByCloser) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.treasurySignatoryCloserHint,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.terreCuite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
