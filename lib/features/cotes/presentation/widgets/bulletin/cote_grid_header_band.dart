import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_scrolled_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête des trois zones, posé en haut de la pile de la grille. Quand la
/// page défile au-delà, il reste collé au haut de l'écran — jusqu'au pied de
/// la grille, qu'il ne recouvre pas. La partie des notes suit le défilement
/// de côté de [horizontal].
class CoteGridHeaderBand extends StatefulWidget {
  final CoteGridContext grid;

  /// Vrai si les notes tiennent : elles ont alors leur largeur. Sinon elles
  /// défilent dans ce qui reste entre les cours et le total.
  final bool fits;
  final ScrollController horizontal;

  const CoteGridHeaderBand({
    super.key,
    required this.grid,
    required this.fits,
    required this.horizontal,
  });

  @override
  State<CoteGridHeaderBand> createState() => _CoteGridHeaderBandState();
}

class _CoteGridHeaderBandState extends State<CoteGridHeaderBand> {
  final _stuck = ValueNotifier<double>(0);
  ScrollableState? _page;

  /// La position écoutée, gardée pour elle-même : la page en refait une
  /// (zoom du navigateur, écran d'une autre échelle) sans changer d'état, et
  /// l'ancienne ne bouge plus.
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _page = Scrollable.maybeOf(context, axis: Axis.vertical);
    final position = _page?.position;
    if (position == _position) return;
    _position?.removeListener(_measure);
    _position = position?..addListener(_measure);
  }

  @override
  void dispose() {
    _position?.removeListener(_measure);
    _stuck.dispose();
    super.dispose();
  }

  /// Le décalage qui ramène l'en-tête en haut de la page visible, borné par la
  /// grille : rien tant que son haut est à l'écran.
  void _measure() {
    if (!mounted) return;
    final band = context.findRenderObject() as RenderBox?;
    final stack = context.findAncestorRenderObjectOfType<RenderStack>();
    final viewport = _page?.context.findRenderObject() as RenderBox?;
    if (band == null || stack == null || viewport == null) return;
    if (!band.attached || !stack.hasSize || !viewport.attached) return;
    final top = band.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final heights = widget.grid.heights;
    final foot =
        heights.maxima +
        heights.total +
        (widget.grid.hasGroupTotals ? heights.percent : 0);
    final limit = math.max(0.0, stack.size.height - widget.grid.rowsTop - foot);
    _stuck.value = (-top).clamp(0.0, limit);
  }

  @override
  Widget build(BuildContext context) {
    // La hauteur de la grille change (rubrique repliée, autre forme) sans que
    // la page défile : on remesure après chaque construction.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final grid = widget.grid;
    final metrics = grid.metrics;
    final band = SizedBox(
      height: grid.rowsTop,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: metrics.courseWidth,
            child: _Fixed(
              grid: grid,
              label: AppLocalizations.of(context)!.coteColumnCours,
              alignment: Alignment.centerLeft,
            ),
          ),
          if (widget.fits) ...[
            SizedBox(
              width: metrics.centerWidth,
              child: _Notes(grid: grid),
            ),
            SizedBox(
              width: metrics.totalWidth,
              child: _TotalHeader(grid: grid),
            ),
          ] else ...[
            Expanded(
              child: CoteGridScrolledHeader(
                width: metrics.centerWidth,
                horizontal: widget.horizontal,
                child: _Notes(grid: grid),
              ),
            ),
            SizedBox(
              width: metrics.totalWidth,
              child: _TotalHeader(grid: grid),
            ),
          ],
        ],
      ),
    );
    return ValueListenableBuilder<double>(
      valueListenable: _stuck,
      child: band,
      builder: (context, offset, band) => Transform.translate(
        offset: Offset(0, offset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: offset > 0 ? AppElevation.shadowCard : null,
          ),
          child: band,
        ),
      ),
    );
  }
}

/// Les titres des colonnes de notes, et au-dessus, en portée année, ceux des
/// groupes.
class _Notes extends StatelessWidget {
  final CoteGridContext grid;

  const _Notes({required this.grid});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (grid.hasGroupTotals) CoteGroupBand(grid: grid),
      CoteHeaderRow(grid: grid),
    ],
  );
}

class _TotalHeader extends StatelessWidget {
  final CoteGridContext grid;

  const _TotalHeader({required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = grid.hasGroupTotals
        ? l10n.coteColumnAnnual
        : grid.columns.length == 1 || grid.metrics.phone
        ? l10n.coteColumnTotal
        : l10n.coteColumnTotalScope(
            CoteLabels.firstGroupShort(l10n, grid.classe, grid.columns),
          );
    return _Fixed(grid: grid, label: label, alignment: Alignment.centerRight);
  }
}

/// L'en-tête d'une colonne figée : le bandeau des groupes au-dessus, vide.
class _Fixed extends StatelessWidget {
  final CoteGridContext grid;
  final String label;
  final Alignment alignment;

  const _Fixed({
    required this.grid,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bleuProfond,
      padding: EdgeInsets.only(
        top: grid.hasGroupTotals ? grid.heights.group : 0,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      alignment: alignment,
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
