import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/fields/numbered_line_row.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_duree.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau gris du cadre, en lecture (spec S2) : Durée | Au programme |
/// Consignes. Une rubrique vide est tue.
class SujetCadreBand extends StatelessWidget {
  final EvaluationCadre cadre;

  const SujetCadreBand({super.key, required this.cadre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duree = cadre.dureeMinutes;
    final consignes = cadre.consignes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        children: [
          _Rubrique(
            label: l10n.sujetDureeLabel,
            child: _text(
              duree == null ? l10n.dureeUndefined : formatDuree(l10n, duree),
            ),
          ),
          if (cadre.programme.isNotEmpty)
            _Rubrique(
              label: l10n.sujetProgrammeLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, line) in cadre.programme.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NumberedLineBadge(i + 1),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: _text(line)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (consignes != null)
            _Rubrique(label: l10n.sujetConsignesLabel, child: _text(consignes)),
        ],
      ),
    );
  }

  Widget _text(String value) => Text(
    value,
    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
  );
}

class _Rubrique extends StatelessWidget {
  final String label;
  final Widget child;

  const _Rubrique({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppDimensions.sujetCadreRubriqueMaxWidth,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    ),
  );
}
