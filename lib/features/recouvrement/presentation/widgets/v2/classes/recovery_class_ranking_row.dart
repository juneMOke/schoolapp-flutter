import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_name.dart';

/// Une classe du bloc D (D7) : « 7ème EB · 17/48 soldés · 21 sans paiement ·
/// 45 % · reste 9 534 $ », la barre du taux, et l'œil.
///
/// **Toute la ligne est la cible** (≥ 48 dp) : l'œil n'est qu'un repère, il
/// n'ajoute pas d'arrêt de tabulation. [tone] est la couleur de la colonne
/// (vert en tête, rouge à relancer, neutre pour « Non affectés »).
class RecoveryClassRankingRow extends StatelessWidget {
  final RecoveryClassFeeRow row;
  final Color tone;

  /// Sous 600 de largeur reçue : la barre passe sous le nom.
  final bool narrow;
  final VoidCallback onTap;

  const RecoveryClassRankingRow({
    super.key,
    required this.row,
    required this.tone,
    required this.narrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = row.ratePercent;
    final rateText = rate == null
        ? l10n.recoveryClassesRateNone
        : l10n.recoveryClassesRate(rate);
    final counts = l10n.recoveryClassesCounts(
      row.settledStudents,
      row.billedStudents,
      row.noPaymentStudents,
    );
    final name = row.displayName(l10n);
    final rest = l10n.recoveryClassesOutstanding(
      MoneyFormat.compact(row.outstanding),
    );
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: [
        l10n.recoveryClassesView(name),
        counts,
        rateText,
        rest,
      ].join(' · '),
      builder: (context, highlight) => ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: highlight.any
                ? AppColors.surfaceAlt
                : AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: highlight.focused
                  ? AppColors.bleuArdoise
                  : AppColors.border,
              width: highlight.focused ? 2 : 1,
            ),
          ),
          child: narrow
              ? _narrow(name, counts, rateText, rest)
              : _wide(name, counts, rateText, rest),
        ),
      ),
    );
  }

  Widget _identity(String name, String counts) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
      ),
      Text(
        counts,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMutedAa,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  Widget _bar() => RecoveryRateBar(percent: row.ratePercent ?? 0, color: tone);

  Widget _figures(String rateText, String rest) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        rateText,
        style: AppTypography.labelLarge.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      Text(
        rest,
        textAlign: TextAlign.end,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMutedAa,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  Widget _wide(String name, String counts, String rateText, String rest) => Row(
    children: [
      Expanded(flex: 12, child: _identity(name, counts)),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        flex: 10,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.recoveryClassBarMinWidth,
          ),
          child: _bar(),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      _figures(rateText, rest),
      const SizedBox(width: AppSpacing.md),
      const RecoveryEye(),
    ],
  );

  /// Sous 600 : le nom prend sa ligne (avec l'œil), les comptes dessous,
  /// puis la barre et le taux côte à côte.
  Widget _narrow(String name, String counts, String rateText, String rest) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _identity(name, counts)),
              const SizedBox(width: AppSpacing.md),
              const RecoveryEye(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Row(
            children: [
              Expanded(child: _bar()),
              const SizedBox(width: AppSpacing.md),
              _figures(rateText, rest),
            ],
          ),
        ],
      );
}

/// La barre d'un taux (`RecFill`) : piste papier, part pleine dans [color].
class RecoveryRateBar extends StatelessWidget {
  final int percent;
  final Color color;
  final Color track;
  final double height;

  const RecoveryRateBar({
    super.key,
    required this.percent,
    required this.color,
    this.track = AppColors.surfaceAlt,
    this.height = AppDimensions.recoveryClassBarHeight,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.brPill,
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: track),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: percent.clamp(0, 100) / 100,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    ),
  );
}

/// L'œil « voir le détail » (`RecEye`) : un repère, pas un bouton — la ligne
/// entière porte le geste.
class RecoveryEye extends StatelessWidget {
  const RecoveryEye({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.recoveryClassEyeSize,
    height: AppDimensions.recoveryClassEyeSize,
    decoration: BoxDecoration(
      color: AppColors.bleuArdoiseSoft,
      borderRadius: BorderRadius.circular(AppDimensions.recoveryClassEyeRadius),
    ),
    child: const Icon(
      Icons.visibility_outlined,
      size: AppDimensions.recoveryClassEyeIconSize,
      color: AppColors.bleuArdoise,
    ),
  );
}
