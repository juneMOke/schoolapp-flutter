import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le fond d'une ligne de titre, posé par chacune des trois zones. Un domaine
/// est un bandeau plein ; une branche, un bandeau clair qu'un filet appuyé
/// sépare de ses cours.
class CoteRubriqueStrip extends StatelessWidget {
  final CoteRubriqueRow row;
  final CoteGridContext grid;

  const CoteRubriqueStrip({super.key, required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.of(row),
      decoration: BoxDecoration(
        color: row.isDomain ? row.tone.strong : row.tone.soft,
        border: row.isDomain
            ? null
            : Border(
                bottom: BorderSide(
                  color: row.tone.ink,
                  width: AppDimensions.coteBranchRule,
                ),
              ),
      ),
    );
  }
}

/// Le fond d'un sous-total, filet de sa rubrique au-dessus.
class CoteSubtotalStrip extends StatelessWidget {
  final CoteSubtotalRow row;
  final CoteGridContext grid;
  final Widget child;

  const CoteSubtotalStrip({
    super.key,
    required this.row,
    required this.grid,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.of(row),
      decoration: BoxDecoration(
        color: row.tone.soft,
        border: Border(
          top: BorderSide(
            color: row.tone.ink,
            width: AppDimensions.coteSubtotalRule,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Les titres de domaine et de branche, à placer dans la pile de la grille. Ils
/// couvrent toute sa largeur : aucun ne se coupe sur la colonne des cours.
List<Widget> coteRubriqueTitles(CoteGridContext grid) {
  final titles = <Widget>[];
  var top = grid.rowsTop;
  for (final row in grid.rows) {
    final height = grid.heights.of(row);
    if (row is CoteRubriqueRow) {
      titles.add(
        Positioned(
          key: ValueKey(row.id),
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: _RubriqueTitle(row: row, grid: grid),
        ),
      );
    }
    top += height;
  }
  return titles;
}

/// Un titre replie ou déplie sa rubrique d'un appui. Il reste hors de Tab :
/// passer d'une note à l'autre ne doit pas s'y arrêter.
class _RubriqueTitle extends StatelessWidget {
  final CoteRubriqueRow row;
  final CoteGridContext grid;

  const _RubriqueTitle({required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final domain = row.isDomain;
    final phone = grid.metrics.phone;
    final label = (row.rubrique.label ?? '').toUpperCase();
    final ink = domain ? AppColors.textOnDark : row.tone.ink;
    final style = domain
        ? AppTypography.bulletinDomain.copyWith(
            color: ink,
            fontSize: phone ? AppTypography.bulletinBranch.fontSize : null,
          )
        : AppTypography.bulletinBranch.copyWith(color: AppColors.noirChaud);
    final text = EteeloOverflowText(
      label,
      textAlign: domain ? TextAlign.center : null,
      maxLines: phone ? 2 : 1,
      style: style,
    );
    final chevron = AnimatedRotation(
      turns: row.collapsed ? -0.25 : 0,
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      child: Icon(
        Icons.expand_more_rounded,
        size: AppDimensions.coteChevron,
        color: ink,
      ),
    );
    final alert = row.collapsed ? _HiddenAlert(row: row, grid: grid) : null;
    return ExcludeFocusTraversal(
      child: Semantics(
        button: true,
        expanded: !row.collapsed,
        label: row.rubrique.label,
        hint: row.collapsed
            ? l10n.coteRubriqueExpand
            : l10n.coteRubriqueCollapse,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => grid.onToggleRubrique(row.rubrique.id),
            hoverColor: domain
                ? AppColors.stateFocusOnDark
                : AppColors.stateHover,
            child: Padding(
              padding: EdgeInsets.only(
                left: domain
                    ? AppSpacing.md
                    : AppSpacing.md + (row.depth - 1) * AppSpacing.md,
                right: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: domain
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  chevron,
                  const SizedBox(width: AppSpacing.xs),
                  if (domain) Flexible(child: text) else Expanded(child: text),
                  if (alert != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    alert,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une rubrique repliée ne cache pas une cote à corriger ni une cote refusée.
class _HiddenAlert extends StatelessWidget {
  final CoteRubriqueRow row;
  final CoteGridContext grid;

  const _HiddenAlert({required this.row, required this.grid});

  bool _hasAlert(CoteSaisieState state) {
    if (state is! CoteSaisieReady) return false;
    for (final cours in row.rubrique.allCours) {
      for (final column in grid.columns) {
        final cell = state.cells.cell(grid.studentId, cours.coursId, column.id);
        if (cell != null && (cell.isInvalid || cell.isRejected)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CoteSaisieBloc, CoteSaisieState, bool>(
      selector: _hasAlert,
      builder: (context, alert) => alert
          ? Icon(
              Icons.error_rounded,
              size: AppDimensions.coteChevron,
              color: row.isDomain ? AppColors.orDoux : AppColors.error,
              semanticLabel: AppLocalizations.of(context)!.coteRubriqueAlert,
            )
          : const SizedBox.shrink(),
    );
  }
}
