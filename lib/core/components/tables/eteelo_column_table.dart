import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_row_scope.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_rule.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table_cards.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_frozen_column.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_min_width_scroll.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une rangée de cellules aux largeurs partagées par l'en-tête et les lignes :
/// `null` = la colonne qui prend le reste.
///
/// Sous un [EteeloFrozenColumn], la première cellule reste à l'écran quand le
/// tableau défile de côté, posée sur [frozenBackground].
class EteeloColumns extends StatelessWidget {
  final List<double?> widths;
  final List<Widget> cells;

  /// Fond de la cellule figée : il masque les colonnes qui passent dessous.
  final Color frozenBackground;

  /// Marge gauche de la rangée qui porte ces cellules, que le masque couvre.
  final double frozenInset;

  const EteeloColumns({
    super.key,
    required this.widths,
    required this.cells,
    this.frozenBackground = AppColors.surfaceRaised,
    this.frozenInset = AppSpacing.sm,
  }) : assert(widths.length == cells.length);

  Widget _sized(int index, Widget cell, EteeloColumnRule? rule) {
    final padding = rule?.paddingOf(index);
    final spaced = padding == null
        ? cell
        : Padding(padding: padding, child: cell);
    return widths[index] == null
        ? Expanded(child: spaced)
        : SizedBox(width: widths[index], child: spaced);
  }

  @override
  Widget build(BuildContext context) {
    final rule = EteeloColumnRule.maybeOf(context);
    Widget sized(int index, Widget cell) => _sized(index, cell, rule);
    final frozen = EteeloFrozenColumn.maybeOf(context);
    if (frozen == null || !frozen.active) {
      return Row(
        children: [for (final (i, cell) in cells.indexed) sized(i, cell)],
      );
    }
    // Disposée de droite à gauche, la rangée peint sa première cellule en
    // DERNIER : translatée du décalage, elle passe par-dessus les montants,
    // et reçoit les appuis la première. Aucune copie : la cellule reste
    // celle qu'on lit et qu'on trouve, et elle seule donne sa hauteur.
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (var i = cells.length - 1; i > 0; i--) sized(i, cells[i]),
        sized(0, _frozenLead(frozen)),
      ],
    );
  }

  Widget _frozenLead(EteeloFrozenColumn frozen) => AnimatedBuilder(
    animation: frozen.controller,
    builder: (context, child) =>
        Transform.translate(offset: Offset(frozen.offset, 0), child: child),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Le masque déborde sur les marges de la rangée : sans lui, les
        // montants transparaissaient sur ses 8 dp de gauche. ⚠️ Il suit la
        // hauteur de la cellule figée : une colonne voisine plus haute
        // qu'elle laisserait voir ce qui passe au-dessus et au-dessous.
        Positioned(
          left: -frozenInset,
          top: -frozenInset,
          bottom: -frozenInset,
          right: 0,
          child: ColoredBox(color: frozenBackground),
        ),
        Align(alignment: Alignment.centerLeft, child: cells.first),
      ],
    ),
  );
}

/// Un tableau à colonnes fixes (récapitulatifs du Pointage et de l'appel,
/// livre de paie, avances, historique) : un en-tête gris, des lignes
/// filetées, et un défilement horizontal sous [minWidth]
/// ([EteeloMinWidthScroll]).
class EteeloColumnTable extends StatefulWidget {
  final double minWidth;
  final List<double?> widths;
  final List<String> headers;

  /// Colonnes dont l'en-tête s'aligne à droite (montants).
  final Set<int> endAligned;
  final int rowCount;
  final Widget Function(BuildContext context, int index) row;

  /// Une ligne de pied (total), facultative.
  final Widget? footer;

  /// La première colonne (qui, de quoi) reste à l'écran quand le tableau
  /// défile de côté (cf. [EteeloFrozenColumn]).
  final bool frozenFirstColumn;

  /// Habillage teinté : bandeau d'en-tête plein, zébrure, cadre. `null` — le
  /// défaut — garde l'en-tête gris historique.
  final DataTableTone? tone;

  /// Sous cette largeur reçue, une carte par ligne
  /// ([EteeloColumnTableCards]) ; `null` — le défaut — : toujours en colonnes,
  /// défilement de côté sous [minWidth].
  final double? cardsBelow;

  /// Un filet vertical après cette colonne, sur toute la hauteur du tableau :
  /// il sépare deux groupes de colonnes. `null` — le défaut — : aucun.
  final int? ruleAfter;

  /// Le tableau mis en avant : posé sur une carte blanche, ombrée et
  /// arrondie, son en-tête collé au cadre. Faux — le défaut — : à plat.
  final bool raised;

  const EteeloColumnTable({
    super.key,
    required this.minWidth,
    required this.widths,
    required this.headers,
    required this.rowCount,
    required this.row,
    this.endAligned = const {},
    this.footer,
    this.frozenFirstColumn = false,
    this.tone,
    this.cardsBelow,
    this.ruleAfter,
    this.raised = false,
  });

  @override
  State<EteeloColumnTable> createState() => _EteeloColumnTableState();
}

class _EteeloColumnTableState extends State<EteeloColumnTable> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// La colonne figée dans la largeur plancher : la sienne, ou ce que les
  /// autres laissent (moins les marges de la rangée).
  double get _frozenWidth {
    final own = widget.widths.first;
    if (own != null) return own;
    final others = widget.widths
        .skip(1)
        .fold<double>(0, (sum, width) => sum + (width ?? 0));
    return widget.minWidth - others - 2 * AppSpacing.sm;
  }

  List<Widget> _rows(BuildContext context) => [
    for (var index = 0; index < widget.rowCount; index++)
      EteeloColumnRowScope(
        zebra: index.isOdd ? widget.tone?.zebra : null,
        child: Builder(builder: (context) => widget.row(context, index)),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final cardsBelow = widget.cardsBelow;
    if (cardsBelow == null) return _table(context);
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < cardsBelow
          ? EteeloColumnTableCards(
              headers: widget.headers,
              rows: [
                for (var index = 0; index < widget.rowCount; index++)
                  widget.row(context, index),
              ],
              footer: widget.footer,
              tone: widget.tone,
            )
          : _table(context),
    );
  }

  Widget _table(BuildContext context) {
    final tone = widget.tone;
    final headerBackground = tone?.header ?? AppColors.surfaceAlt;
    final table = EteeloMinWidthScroll(
      minWidth: widget.minWidth,
      controller: _scroll,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: headerBackground,
              borderRadius: widget.raised ? null : AppRadius.brSm,
            ),
            child: EteeloColumns(
              widths: widget.widths,
              frozenBackground: headerBackground,
              cells: [
                for (final (index, text) in widget.headers.indexed)
                  EteeloOverflowText(
                    text.toUpperCase(),
                    textAlign: widget.endAligned.contains(index)
                        ? TextAlign.end
                        : TextAlign.start,
                    style: AppTypography.labelSmall.copyWith(
                      color: tone?.headerInk ?? AppColors.textMutedAa,
                    ),
                  ),
              ],
            ),
          ),
          ..._rows(context),
          ?widget.footer,
        ],
      ),
    );
    final ruleAfter = widget.ruleAfter;
    final ruled = ruleAfter == null
        ? table
        : EteeloColumnRule(
            after: ruleAfter,
            widths: widget.widths,
            color: tone?.border ?? AppColors.border,
            child: table,
          );
    final framed = widget.raised
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: tone?.border ?? AppColors.border),
              boxShadow: AppElevation.shadowCard,
            ),
            child: ClipRRect(borderRadius: AppRadius.brLg, child: ruled),
          )
        : tone == null
        ? ruled
        : DecoratedBox(decoration: tone.frame, child: ruled);
    if (!widget.frozenFirstColumn) return framed;
    return LayoutBuilder(
      builder: (context, constraints) => EteeloFrozenColumn(
        controller: _scroll,
        width: _frozenWidth,
        active: constraints.maxWidth < widget.minWidth,
        child: framed,
      ),
    );
  }
}

/// Une ligne de [EteeloColumnTable] : filet bas, toucher facultatif.
class EteeloColumnTableRow extends StatelessWidget {
  final List<double?> widths;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? background;

  const EteeloColumnTableRow({
    super.key,
    required this.widths,
    required this.cells,
    this.onTap,
    this.background,
  });

  /// Le style des chiffres d'une cellule : tabulaires, pour qu'ils
  /// s'alignent d'une ligne à l'autre.
  static TextStyle figures({Color? color, bool strong = false}) =>
      (strong ? AppTypography.labelLarge : AppTypography.bodyMedium).copyWith(
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Le fond est porté par le `Material` et non par le `Container` : l'encre
  // de l'`InkWell` (survol, focus, appui) se peint SOUS l'enfant, et un fond
  // opaque posé dessus la masquait — la ligne ne réagissait plus à rien.
  @override
  Widget build(BuildContext context) {
    final background = this.background ?? EteeloColumnRowScope.zebraOf(context);
    return Material(
      type: background == null
          ? MaterialType.transparency
          : MaterialType.canvas,
      color: background,
      child: InkWell(
        onTap: onTap,
        child: EteeloColumnRule.under(
          context,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: EteeloColumns(
              widths: widths,
              cells: cells,
              frozenBackground: background ?? AppColors.surfaceRaised,
            ),
          ),
        ),
      ),
    );
  }
}
