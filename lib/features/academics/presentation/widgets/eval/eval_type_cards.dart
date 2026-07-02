import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Défaut de barème + poids d'un type d'évaluation (spec §2).
({double max, int poids}) evalTypeDefaults(TypeEvaluation type) =>
    switch (type) {
      TypeEvaluation.interro => (max: 10, poids: 1),
      TypeEvaluation.devoir => (max: 20, poids: 2),
      TypeEvaluation.examen => (max: 40, poids: 1),
      TypeEvaluation.unknown => (max: 10, poids: 1),
    };

/// Trois cartes radio de type (spec §2). Choisir un type applique ses défauts
/// (géré par l'appelant via [onChanged]).
class EvalTypeCards extends StatelessWidget {
  final TypeEvaluation selected;
  final ValueChanged<TypeEvaluation> onChanged;

  static const List<TypeEvaluation> _types = [
    TypeEvaluation.interro,
    TypeEvaluation.devoir,
    TypeEvaluation.examen,
  ];

  const EvalTypeCards({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _types.length; i++) ...[
          Expanded(
            child: _TypeCard(
              type: _types[i],
              isSelected: _types[i] == selected,
              onTap: () => onChanged(_types[i]),
            ),
          ),
          if (i < _types.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final TypeEvaluation type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = evalTypeVisual(type);
    return Semantics(
      button: true,
      selected: isSelected,
      label: typeEvaluationLabel(l10n, type),
      child: Material(
        color: isSelected ? visual.soft : AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: isSelected ? visual.color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  visual.icon,
                  size: 20,
                  color: isSelected ? visual.color : AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  typeEvaluationLabel(l10n, type),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? visual.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
