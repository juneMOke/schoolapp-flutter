import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de sélection repliée, une fois la classe ouverte : « classe ·
/// portée » et « Changer ». Le bulletin remonte sous les yeux, au lieu d'attendre
/// sous la cascade.
class CoteSelectionSummary extends StatelessWidget {
  final String summary;
  final VoidCallback onChange;

  const CoteSelectionSummary({
    super.key,
    required this.summary,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LeadingTrailingRow(
      gap: AppSpacing.md,
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(l10n.coteSaisieEyebrow),
          const SizedBox(height: 2),
          EteeloOverflowText(
            summary,
            maxLines: 2,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.bleuProfond,
            ),
          ),
        ],
      ),
      trailing: EteeloButton.secondary(
        label: l10n.coteSelectionChange,
        icon: Icons.tune_rounded,
        fullWidth: false,
        tooltip: l10n.coteSelectionChangeHint,
        onPressed: onChange,
      ),
    );
  }
}

/// Le titre de la carte dépliée ; « Replier » quand une classe est ouverte.
class CoteSelectionHeading extends StatelessWidget {
  final VoidCallback? onCollapse;

  const CoteSelectionHeading({super.key, this.onCollapse});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onCollapse = this.onCollapse;
    return LeadingTrailingRow(
      gap: AppSpacing.md,
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(l10n.coteSaisieEyebrow),
          const SizedBox(height: 2),
          Text(
            l10n.coteSaisieTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bleuProfond,
            ),
          ),
        ],
      ),
      trailing: onCollapse == null
          ? const SizedBox.shrink()
          : EteeloButton.ghost(
              label: l10n.coteSelectionCollapse,
              icon: Icons.expand_less_rounded,
              fullWidth: false,
              onPressed: onCollapse,
            ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.labelSmall.copyWith(
      color: AppColors.terreCuite,
      letterSpacing: 1.2,
    ),
  );
}
