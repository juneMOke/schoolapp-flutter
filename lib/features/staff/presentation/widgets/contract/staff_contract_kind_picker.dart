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

/// Les trois statuts en tuiles égales : la tuile choisie prend le voile et la
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
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in StaffContractKind.values)
          SizedBox(
            width: AppDimensions.staffContractTileWidth,
            child: _Tile(
              title: StaffLabels.contract(l10n, kind),
              hint: hint(kind),
              tone: StaffContractTone.of(kind),
              selected: selected == kind,
              onTap: () => onChanged(kind),
            ),
          ),
      ],
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
          width: 1.5,
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
                  Icon(tone.icon, size: 18, color: tone.ink),
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
