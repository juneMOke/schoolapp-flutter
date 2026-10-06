import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/bloc_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// La barre « Ajouter un bloc », toujours visible en pied du contenu en
/// édition : un bouton par type ; le bloc vide s'ajoute en fin.
class ContenuAddBar extends StatelessWidget {
  final ValueChanged<ChapitreBlocType>? onAdd;

  const ContenuAddBar({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final add = onAdd;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.contenuAddBloc.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        for (final type in ChapitreBlocType.values)
          OutlinedButton.icon(
            onPressed: add == null ? null : () => add(type),
            icon: Icon(BlocVisual.icon(type), size: ProgrammeLayout.iconSmall),
            label: Text(BlocVisual.short(l10n, type)),
            // Dans un `Wrap`, la largeur minimale du thème serait infinie.
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
          ),
      ],
    );
  }
}
