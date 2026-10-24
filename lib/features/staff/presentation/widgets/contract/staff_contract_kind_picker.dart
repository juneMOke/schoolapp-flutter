import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois statuts en tuiles égales, sur toute la largeur : la tuile choisie prend le voile et la
/// bordure de son contrat, et dit ce que le statut implique.
class StaffContractKindPicker extends StatelessWidget {
  final StaffContractKind? selected;
  final ValueChanged<StaffContractKind> onChanged;

  const StaffContractKindPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String hint(StaffContractKind kind) => switch (kind) {
      StaffContractKind.permanent => l10n.staffContractPermanentHint,
      StaffContractKind.vacataire => l10n.staffContractVacataireHint,
      StaffContractKind.conventionne => l10n.staffContractConventionneHint,
    };
    Widget tile(StaffContractKind kind) => _Tile(
      title: StaffLabels.contract(l10n, kind),
      hint: hint(kind),
      tone: StaffContractTone.of(kind),
      selected: selected == kind,
      onTap: () => onChanged(kind),
    );
    const kinds = StaffContractKind.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inRow =
            constraints.maxWidth >=
            kinds.length * AppDimensions.staffContractTileWidth +
                (kinds.length - 1) * AppSpacing.sm;
        // Côte à côte, les trois tuiles partagent la largeur et la hauteur ;
        // à l'étroit, elles s'empilent sur toute la largeur.
        if (!inRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in kinds) ...[
                if (kind != kinds.first) const SizedBox(height: AppSpacing.sm),
                tile(kind),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in kinds) ...[
                if (kind != kinds.first) const SizedBox(width: AppSpacing.sm),
                Expanded(child: tile(kind)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String hint;
  final StaffContractTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.title,
    required this.hint,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? tone.soft : AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(
          color: selected ? tone.color : AppColors.border,
          width: AppDimensions.staffContractTileBorderWidth,
        ),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    tone.icon,
                    size: AppDimensions.staffContractTileIconSize,
                    color: tone.ink,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(color: tone.ink),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
