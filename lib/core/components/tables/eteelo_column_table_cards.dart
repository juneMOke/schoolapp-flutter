import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un [EteeloColumnTable] sur un téléphone : une carte par ligne, la première
/// cellule en titre, chaque cellule suivante sur sa ligne, nommée par sa
/// colonne. Comprimées à 360 dp, les colonnes coupaient les montants ; en
/// carte, chacun a la largeur de l'écran.
///
/// Les cartes sont tirées des lignes elles-mêmes : un tableau n'écrit pas deux
/// fois ses cellules. Un widget qui n'est ni une [EteeloColumnTableRow] ni
/// une colonne de lignes (un intertitre) se pose tel quel.
class EteeloColumnTableCards extends StatelessWidget {
  final List<String> headers;
  final List<Widget> rows;
  final Widget? footer;
  final DataTableTone? tone;

  const EteeloColumnTableCards({
    super.key,
    required this.headers,
    required this.rows,
    this.footer,
    this.tone,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final row in rows) ..._cardsOf(row),
      if (footer case final footer?) ..._cardsOf(footer),
    ],
  );

  /// Une ligne devient une carte ; une colonne de lignes (un groupe, un total
  /// par devise) se déplie en autant de cartes ; le reste (un intertitre) se
  /// pose tel quel.
  List<Widget> _cardsOf(Widget widget) => switch (widget) {
    EteeloColumnTableRow() => [_card(widget)],
    Column(:final children) => [
      for (final child in children) ..._cardsOf(child),
    ],
    _ => [widget],
  };

  Widget _card(Widget row) {
    if (row is! EteeloColumnTableRow) return row;
    // Un intertitre de groupe (seule sa première cellule parle) n'est pas une
    // ligne : il se pose en titre, sans cadre de carte.
    if (row.cells.skip(1).every(_isBlank)) {
      return Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: row.cells.first,
      );
    }
    final fields = [
      for (var i = 1; i < row.cells.length && i < headers.length; i++)
        if (!_isBlank(row.cells[i]))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: LeadingTrailingRow(
              gap: AppSpacing.md,
              maxTrailingShare: 0.6,
              leading: Text(
                headers[i],
                style: AppTypography.labelSmall.copyWith(
                  color: row.labelInk ?? AppColors.textMutedAa,
                ),
              ),
              // `widthFactor` : la valeur garde sa largeur, le nom de colonne
              // prend le reste ; sans lui, l'Align remplissait toujours 60 %.
              trailing: Align(
                alignment: AlignmentDirectional.centerEnd,
                widthFactor: 1,
                child: row.cells[i],
              ),
            ),
          ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: row.background ?? AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: tone?.border ?? AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: row.onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [row.cells.first, ...fields],
            ),
          ),
        ),
      ),
    );
  }

  /// Une cellule laissée vide pour tenir l'alignement des colonnes.
  static bool _isBlank(Widget cell) => cell is SizedBox && cell.child == null;
}
