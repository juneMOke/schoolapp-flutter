import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La portée de la saisie et sa cible. Le découpage ne se choisit pas : il vient
/// du cycle de la classe, on l'affiche seulement.
class CoteScopeBar extends StatelessWidget {
  final CoteClasse classe;
  final CoteScope scope;
  final List<CoteColumn> year;
  final ValueChanged<CoteScope> onChanged;

  const CoteScopeBar({
    super.key,
    required this.classe,
    required this.scope,
    required this.year,
    required this.onChanged,
  });

  bool get _trimestres => classe.decoupage == Decoupage.trimestre;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inputs = year.where((c) => c.isInput).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _trimestres
                  ? l10n.coteDecoupageTrimestres
                  : l10n.coteDecoupageSemestres,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SegmentedTabFilter<CotePortee>(
              selected: scope.portee,
              onSelected: (portee) => _onPortee(portee, inputs),
              semanticsLabel: l10n.cotePorteeSemantics,
              wrap: true,
              options: [
                SegmentedTabOption(
                  label: l10n.cotePorteeColonne,
                  value: CotePortee.colonne,
                ),
                SegmentedTabOption(
                  label: _trimestres
                      ? l10n.cotePorteeUnTrimestre
                      : l10n.cotePorteeUnSemestre,
                  value: CotePortee.groupe,
                ),
                SegmentedTabOption(
                  label: _trimestres
                      ? l10n.cotePorteeLesTrimestres
                      : l10n.cotePorteeLesSemestres,
                  value: CotePortee.annee,
                ),
              ],
            ),
          ],
        ),
        if (scope.portee != CotePortee.annee) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: l10n.coteGroupChipSemantics,
            container: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: scope.portee == CotePortee.colonne
                  ? _columnChips(l10n, inputs)
                  : _groupChips(l10n, inputs),
            ),
          ),
        ],
      ],
    );
  }

  /// Passer d'une portée à l'autre reste dans le même groupe.
  void _onPortee(CotePortee portee, List<CoteColumn> inputs) {
    final group = _currentGroup(inputs);
    onChanged(switch (portee) {
      CotePortee.annee => const CoteScope(portee: CotePortee.annee),
      CotePortee.groupe => CoteScope(portee: portee, cibleId: group),
      CotePortee.colonne => CoteScope(
        portee: portee,
        cibleId: inputs
            .firstWhere((c) => c.periodeId == group, orElse: () => inputs.first)
            .id,
      ),
    });
  }

  String? _currentGroup(List<CoteColumn> inputs) {
    if (scope.portee == CotePortee.groupe) return scope.cibleId;
    if (scope.portee == CotePortee.colonne) {
      return inputs.where((c) => c.id == scope.cibleId).firstOrNull?.periodeId;
    }
    final current = classe.periodes.where((p) => p.courant).firstOrNull;
    return (current ?? classe.periodes.firstOrNull)?.id;
  }

  List<Widget> _groupChips(AppLocalizations l10n, List<CoteColumn> inputs) => [
    for (final periode in classe.periodes)
      _Chip(
        label:
            '${periode.libelle} · ${inputs.where((c) => c.periodeId == periode.id).map((c) => CoteLabels.columnShort(l10n, classe.decoupage, c)).join(' + ')}',
        selected: scope.cibleId == periode.id,
        onTap: () => onChanged(
          CoteScope(portee: CotePortee.groupe, cibleId: periode.id),
        ),
      ),
  ];

  List<Widget> _columnChips(AppLocalizations l10n, List<CoteColumn> inputs) => [
    for (final column in inputs)
      _Chip(
        label: CoteLabels.columnChip(l10n, classe.decoupage, column),
        exam: column.isExamen,
        selected: scope.cibleId == column.id,
        onTap: () => onChanged(
          CoteScope(portee: CotePortee.colonne, cibleId: column.id),
        ),
      ),
  ];
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool exam;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.exam = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = exam ? AppColors.coteExamInk : AppColors.bleuArdoise;
    final Color surface = selected
        ? accent
        : exam
        ? AppColors.coteExamSurface
        : AppColors.surfaceRaised;
    final Color border = selected
        ? accent
        : exam
        ? AppColors.coteExamBorder
        : AppColors.border;
    final Color ink = selected
        ? AppColors.textOnDark
        : exam
        ? AppColors.coteExamInk
        : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      // Le Material porte le fond de la puce (Ink) : survol et focus se
      // peignent par-dessus, et non sous un Container opaque.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brPill,
          // Sur la puce choisie, pleine d'accent, le voile bleu ardoise
          // disparaît : voile blanc cassé.
          focusColor: selected ? AppColors.stateFocusOnDark : null,
          hoverColor: selected ? AppColors.stateHoverOnDark : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: border),
                ),
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
