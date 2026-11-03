import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_center.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_course_zone.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header_band.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_rubrique.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_total_zone.dart';

export 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';

/// La grille : cours figés à gauche, notes au centre, total figé à droite. Les
/// titres de rubrique passent par-dessus les trois zones : un titre centré sur
/// la ligne ne dépend ni de la colonne figée ni du défilement.
/// Toutes les hauteurs sont communes, donc aucune synchronisation de défilement
/// vertical : seule la zone centrale défile, et de côté.
class CoteGrid extends StatefulWidget {
  final CoteMove enterMove;

  /// Les rubriques repliées : le réglage survit au changement d'élève, la
  /// grille non.
  final Set<String> collapsed;
  final ValueChanged<String> onToggleRubrique;

  const CoteGrid({
    super.key,
    required this.enterMove,
    this.collapsed = const {},
    required this.onToggleRubrique,
  });

  @override
  State<CoteGrid> createState() => CoteGridState();
}

class CoteGridState extends State<CoteGrid> {
  late final CoteFocusRegistry _registry;
  late final CoteSaisieReady _opened;
  final _hoveredCours = ValueNotifier<String?>(null);

  /// La zone des notes change de parent quand elle cesse de tenir (rotation,
  /// fenêtre redimensionnée) : sa clé garde ses cases, donc le focus, la
  /// frappe en cours — qui ne s'écrit pas pour autant — et le clavier.
  final _centerKey = GlobalKey(debugLabel: 'CoteGridCenter');

  /// La grille entière, qu'elle grandisse en s'animant ou non.
  final _stackKey = GlobalKey(debugLabel: 'CoteGridStack');

  /// Le défilement de côté des notes, que suit leur en-tête collant.
  final _horizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    _opened = context.read<CoteSaisieBloc>().state as CoteSaisieReady;
    _registry = CoteFocusRegistry(
      studentId: _opened.currentId,
      cours: _orderedCours(),
      columns: _opened.columns,
    );
  }

  @override
  void didUpdateWidget(CoteGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed != widget.collapsed) {
      _registry.cours = _orderedCours();
    }
  }

  List<CoteGridRow> _rows() =>
      coteGridRows(_opened.classe.rubriques, collapsed: widget.collapsed);

  /// L'ordre des lignes à l'écran, celui des flèches et d'Entrée.
  List<CoteCours> _orderedCours() => [
    for (final row in _rows())
      if (row is CoteCourseRow) row.cours,
  ];

  /// La première cellule à remplir : le geste d'arrivée sur un élève.
  void focusFirstEmpty() {
    final state = context.read<CoteSaisieBloc>().state;
    if (state is! CoteSaisieReady) return;
    _registry
        .firstWhereEmpty(
          (course, column) =>
              state.cells
                  .cell(state.currentId, course.coursId, column.id)
                  ?.displayedValue ==
              null,
        )
        ?.requestFocus();
  }

  /// Une case de la grille a le focus.
  bool get hasFocusedCell => _registry.focusedCoursId != null;

  /// Le focus est dans la grille : une case, un titre de rubrique.
  bool get holdsFocus =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<CoteGridState>() ==
      this;

  /// Replie la rubrique la plus proche de la case au focus. Le focus passe
  /// d'abord à la case qui suit la rubrique (sinon à celle qui la précède) :
  /// la case quittée s'écrit, comme à tout départ, et le clavier reste dans
  /// la grille.
  void collapseFocusedRubrique() {
    final coursId = _registry.focusedCoursId;
    if (coursId == null) return;
    CoteRubriqueRow? target;
    for (final row in _rows().whereType<CoteRubriqueRow>()) {
      if (row.collapsed) continue;
      if (!row.rubrique.allCours.any((c) => c.coursId == coursId)) continue;
      if (target == null || row.depth > target.depth) target = row;
    }
    if (target == null) return;
    final inside = {for (final c in target.rubrique.allCours) c.coursId};
    final ordered = _orderedCours();
    final first = ordered.indexWhere((c) => inside.contains(c.coursId));
    final last = ordered.lastIndexWhere((c) => inside.contains(c.coursId));
    final next =
        _registry.firstEditableOf(ordered.skip(last + 1)) ??
        _registry.firstEditableOf(ordered.take(first).toList().reversed);
    if (next != null) {
      next.requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    widget.onToggleRubrique(target.rubrique.id);
  }

  @override
  void dispose() {
    _registry.dispose();
    _hoveredCours.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final metrics = CoteGridMetrics.of(
          width,
          _opened.columns,
          textScale: scale,
        );
        final grid = CoteGridContext(
          classe: _opened.classe,
          columns: _opened.columns,
          gridColumns: coteGridColumns(_opened.columns),
          year: _opened.year,
          cours: _opened.cours,
          rows: _rows(),
          studentId: _opened.currentId,
          metrics: metrics,
          heights: CoteGridHeights(scale, phone: metrics.phone),
          registry: _registry,
          enterMove: widget.enterMove,
          hoveredCours: _hoveredCours,
          onToggleRubrique: widget.onToggleRubrique,
        );
        final center = metrics.centerWidth;
        final room = width - metrics.courseWidth - metrics.totalWidth;
        final fits = center <= room;
        final grow = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.medium;
        // Le total garde sa largeur : étiré sur la place libre d'un poste
        // large, il éloignait le chiffre de sa ligne. La grille s'arrête là,
        // calée à gauche sous l'en-tête du bulletin.
        final used = fits
            ? metrics.courseWidth + center + metrics.totalWidth
            : width;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: used,
            child: _grid(grid, metrics, fits: fits, grow: grow),
          ),
        );
      },
    );
  }

  Widget _grid(
    CoteGridContext grid,
    CoteGridMetrics metrics, {
    required bool fits,
    required Duration grow,
  }) {
    final center = metrics.centerWidth;
    final stack = KeyedSubtree(
      key: _stackKey,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: metrics.courseWidth,
                child: CoteGridCourseZone(grid: grid),
              ),
              if (fits) ...[
                SizedBox(
                  width: center,
                  child: CoteGridCenter(key: _centerKey, grid: grid),
                ),
                SizedBox(
                  width: metrics.totalWidth,
                  child: CoteGridTotalZone(grid: grid),
                ),
              ] else ...[
                Expanded(
                  child: _ScrollingCenter(
                    controller: _horizontal,
                    width: center,
                    child: CoteGridCenter(key: _centerKey, grid: grid),
                  ),
                ),
                SizedBox(
                  width: metrics.totalWidth,
                  child: CoteGridTotalZone(grid: grid),
                ),
              ],
            ],
          ),
          ...coteRubriqueTitles(grid),
          // En dernier : collé en haut de l'écran, il passe par-dessus les
          // lignes et leurs titres.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CoteGridHeaderBand(
              grid: grid,
              fits: fits,
              horizontal: _horizontal,
            ),
          ),
        ],
      ),
    );
    // Sans animation, pas d'AnimatedSize : à durée nulle, il se remet en page
    // pendant sa propre mise en page, et une rotation lève une assertion. La
    // clé garde la grille d'une forme à l'autre.
    if (grow == Duration.zero) return stack;
    return AnimatedSize(
      duration: grow,
      curve: AppMotion.outCurve,
      alignment: Alignment.topCenter,
      child: stack,
    );
  }
}

/// La zone centrale quand elle ne tient pas : elle défile de côté, barre
/// visible, entre les filets des colonnes figées.
class _ScrollingCenter extends StatelessWidget {
  final ScrollController controller;
  final double width;
  final Widget child;

  const _ScrollingCenter({
    required this.controller,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: AppColors.borderStrong),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }
}
