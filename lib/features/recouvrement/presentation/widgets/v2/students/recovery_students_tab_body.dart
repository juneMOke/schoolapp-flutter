import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_tabs.dart';

/// Le contenu d'un onglet : icône et titre, compteur et sous-ligne.
class RecoveryStudentsTabBody extends StatelessWidget {
  final RecoveryStudentsTabData data;
  final bool active;
  final bool narrow;
  final Color tone;
  final String? subtitle;

  const RecoveryStudentsTabBody({
    super.key,
    required this.data,
    required this.active,
    required this.narrow,
    required this.tone,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Un titre ne se coupe pas au milieu d'un mot : à l'étroit (texte
        // ×1,3 au téléphone), la rangée se réduit plutôt.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs + 2,
            children: [
              Icon(data.icon, size: AppSpacing.md + 2, color: tone),
              Text(
                data.title,
                maxLines: 1,
                softWrap: false,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? tone : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _CountLine(
          count: data.count,
          subtitle: narrow ? null : sub,
          tone: tone,
          narrow: narrow,
        ),
      ],
    );
  }
}

class _CountLine extends StatelessWidget {
  final int? count;
  final String? subtitle;
  final Color tone;
  final bool narrow;

  const _CountLine({
    required this.count,
    required this.subtitle,
    required this.tone,
    required this.narrow,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final number = Text(
      count == null ? ' ' : '$count',
      maxLines: 1,
      softWrap: false,
      style: AppTypography.headlineMedium.copyWith(
        fontSize: narrow
            ? AppDimensions.recoveryStudentsTabCountSizeNarrow
            : AppDimensions.recoveryStudentsTabCountSize,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: tone,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.xs + 2,
      children: [
        // Un compteur ne passe jamais à la ligne : il se réduit plutôt.
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: number),
        ),
        if (sub != null)
          Expanded(
            flex: 2,
            child: Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
