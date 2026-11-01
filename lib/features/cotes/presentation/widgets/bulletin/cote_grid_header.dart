import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Portée année : le libellé de chaque groupe au-dessus de ses colonnes.
class CoteGroupBand extends StatelessWidget {
  final CoteGridContext grid;

  const CoteGroupBand({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.group,
      color: AppColors.bleuProfond,
      child: Row(
        children: [
          for (final periode in grid.classe.periodes)
            SizedBox(
              width: grid.gridColumns
                  .where((c) => c.source.periodeId == periode.id)
                  .fold<double>(0, (w, c) => w + grid.metrics.widthOf(c)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.orDoux, width: 2),
                  ),
                ),
                child: Text(
                  periode.libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CoteHeaderRow extends StatelessWidget {
  final CoteGridContext grid;

  const CoteHeaderRow({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final decoupage = grid.classe.decoupage;
    return Container(
      height: grid.heights.header,
      color: AppColors.bleuProfond,
      child: Row(
        children: [
          for (final column in grid.gridColumns)
            SizedBox(
              width: grid.metrics.widthOf(column),
              child: Tooltip(
                message: column.isMax
                    ? CoteLabels.maxLong(l10n, grid.classe, column.source)
                    : CoteLabels.columnLong(l10n, grid.classe, column.source),
                child: Center(
                  child: _HeaderChip(
                    label: column.isMax
                        ? CoteLabels.maxShort(l10n, decoupage, column.source)
                        : CoteLabels.columnShort(
                            l10n,
                            decoupage,
                            column.source,
                          ),
                    column: column,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final CoteGridColumn column;

  const _HeaderChip({required this.label, required this.column});

  @override
  Widget build(BuildContext context) {
    final source = column.source;
    final (Color? background, Color ink) = switch (source.kind) {
      _ when column.isMax => (AppColors.coteMaxSurface, AppColors.bleuArdoise),
      CoteColumnKind.periode => (null, AppColors.textOnDark),
      CoteColumnKind.examen => (
        AppColors.coteExamSurface,
        AppColors.coteExamInk,
      ),
      CoteColumnKind.totalGroupe => (
        AppColors.bleuArdoiseSoft,
        AppColors.bleuProfond,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: background == null
          ? null
          : BoxDecoration(color: background, borderRadius: AppRadius.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (source.locked && source.isInput && !column.isMax) ...[
            Icon(
              Icons.lock_outline_rounded,
              size: AppDimensions.coteHeaderLockIcon,
              color: ink,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: column.isMax ? 2 : 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: ink,
                fontWeight: column.isMax ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
