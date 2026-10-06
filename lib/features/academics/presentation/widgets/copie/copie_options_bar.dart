import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Afficher sur la copie » (spec S5) : cinq interrupteurs. « Réponses » se
/// teinte en vert — cochée, la copie devient un corrigé.
class CopieOptionsBar extends StatelessWidget {
  final CopieOptions options;
  final ValueChanged<CopieOptions> onChanged;

  const CopieOptionsBar({
    super.key,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _toggle(
          l10n.copieOptionProgramme,
          options.programme,
          () => onChanged(options.copyWith(programme: !options.programme)),
        ),
        _toggle(
          l10n.copieOptionPoints,
          options.points,
          () => onChanged(options.copyWith(points: !options.points)),
        ),
        _toggle(
          l10n.copieOptionConsignes,
          options.consignes,
          () => onChanged(options.copyWith(consignes: !options.consignes)),
        ),
        _toggle(
          l10n.copieOptionDuree,
          options.duree,
          () => onChanged(options.copyWith(duree: !options.duree)),
        ),
        _toggle(
          l10n.copieOptionReponses,
          options.reponses,
          () => onChanged(options.copyWith(reponses: !options.reponses)),
          color: AppColors.academicsScoreGood,
          soft: AppColors.academicsScoreGoodSoft,
        ),
      ],
    );
  }

  Widget _toggle(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color color = AppColors.bleuArdoise,
    Color soft = AppColors.bleuArdoiseSoft,
  }) => EteeloFilterChip(
    label: label,
    selected: selected,
    icon: selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
    color: color,
    soft: soft,
    ink: color,
    onTap: onTap,
  );
}
