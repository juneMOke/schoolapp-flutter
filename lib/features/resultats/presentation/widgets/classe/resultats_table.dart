import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_table_sort.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_table_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Table triable roster × sous-période (spec §4). Colonnes : # (rang), Élève,
/// une colonne par sous-période (%), Moyenne du groupe. Les non classés restent
/// toujours en fin de tri. Clic ligne (classée) → vue focus.
class ResultatsTable extends StatefulWidget {
  final ResultatsClasse resultats;
  final String periodeShortLabel;
  final String classroomLabel;
  final ValueChanged<ResultatEleveLigne> onOpenLigne;

  const ResultatsTable({
    super.key,
    required this.resultats,
    required this.periodeShortLabel,
    required this.classroomLabel,
    required this.onOpenLigne,
  });

  @override
  State<ResultatsTable> createState() => _ResultatsTableState();
}

class _ResultatsTableState extends State<ResultatsTable> {
  ResultatsSort? _sort;

  void _onSort(ResultatsSortField field, int index) {
    setState(() {
      final active =
          _sort != null &&
          _sort!.field == field &&
          _sort!.sousPeriodeIndex == index;
      if (active) {
        _sort = ResultatsSort(
          field: field,
          sousPeriodeIndex: index,
          ascending: !_sort!.ascending,
        );
      } else {
        _sort = ResultatsSort(
          field: field,
          sousPeriodeIndex: index,
          // Noms : A→Z ; scores : plus haut d'abord.
          ascending: field == ResultatsSortField.eleve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultats = widget.resultats;
    final sousPeriodes = resultats.sousPeriodes;
    final lignes = applyResultatsSort(resultats.lignes, _sort);
    final seuil = resultats.stats.seuil;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        children: [
          _header(l10n, sousPeriodes.length),
          for (final ligne in lignes)
            ResultatsTableRow(
              ligne: ligne,
              seuil: seuil,
              classroomLabel: widget.classroomLabel,
              sousPeriodeCount: sousPeriodes.length,
              onTap: ligne.nonClasse ? null : () => widget.onOpenLigne(ligne),
            ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n, int sousPeriodeCount) {
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: kResultatsRankColWidth,
            child: Text(l10n.resultatsColumnRank, style: _headerStyle),
          ),
          Expanded(
            flex: kResultatsEleveFlex,
            child: _SortHeader(
              label: l10n.resultatsColumnEleve,
              alignEnd: false,
              active: _sort?.field == ResultatsSortField.eleve,
              ascending: _sort?.ascending ?? true,
              onTap: () => _onSort(ResultatsSortField.eleve, 0),
            ),
          ),
          for (var i = 0; i < sousPeriodeCount; i++)
            Expanded(
              flex: kResultatsPeriodFlex,
              child: _SortHeader(
                label: resultatsSubPeriodColumn(
                  l10n,
                  widget.resultats.sousPeriodes[i].ordre,
                ),
                alignEnd: true,
                active:
                    _sort?.field == ResultatsSortField.sousPeriode &&
                    _sort?.sousPeriodeIndex == i,
                ascending: _sort?.ascending ?? true,
                onTap: () => _onSort(ResultatsSortField.sousPeriode, i),
              ),
            ),
          Expanded(
            flex: kResultatsMoyenneFlex,
            child: _SortHeader(
              label: l10n.resultatsColumnMoyenne(widget.periodeShortLabel),
              alignEnd: true,
              active: _sort?.field == ResultatsSortField.moyenne,
              ascending: _sort?.ascending ?? true,
              onTap: () => _onSort(ResultatsSortField.moyenne, 0),
            ),
          ),
          const SizedBox(width: kResultatsChevronColWidth),
        ],
      ),
    );
  }

  static final TextStyle _headerStyle = AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

class _SortHeader extends StatelessWidget {
  final String label;
  final bool alignEnd;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  const _SortHeader({
    required this.label,
    required this.alignEnd,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: active ? AppColors.bleuArdoise : AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    final children = <Widget>[
      Flexible(
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: style,
        ),
      ),
      if (active)
        Icon(
          ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: AppColors.bleuArdoise,
        ),
    ];

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: alignEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
