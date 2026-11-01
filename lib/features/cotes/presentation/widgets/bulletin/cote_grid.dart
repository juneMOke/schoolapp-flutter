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

  @override
  void dispose() {
    _registry.dispose();
    _hoveredCours.dispose();
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
        return AnimatedSize(
          duration: grow,
          curve: AppMotion.outCurve,
          alignment: Alignment.topCenter,
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
                      child: CoteGridCenter(grid: grid),
                    ),
                    Expanded(child: CoteGridTotalZone(grid: grid)),
                  ] else ...[
                    Expanded(
                      child: _ScrollingCenter(grid: grid, width: center),
                    ),
                    SizedBox(
                      width: metrics.totalWidth,
                      child: CoteGridTotalZone(grid: grid),
                    ),
                  ],
                ],
              ),
              ...coteRubriqueTitles(grid),
            ],
          ),
        );
      },
    );
  }
}

/// La zone centrale quand elle ne tient pas : elle défile de côté, barre
/// visible, entre les filets des colonnes figées.
class _ScrollingCenter extends StatefulWidget {
  final CoteGridContext grid;
  final double width;

  const _ScrollingCenter({required this.grid, required this.width});

  @override
  State<_ScrollingCenter> createState() => _ScrollingCenterState();
}

class _ScrollingCenterState extends State<_ScrollingCenter> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: AppColors.borderStrong),
        ),
      ),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.width,
            child: CoteGridCenter(grid: widget.grid),
          ),
        ),
      ),
    );
  }
}
