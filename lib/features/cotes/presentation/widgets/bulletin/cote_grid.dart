import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_center.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_course_zone.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_total_zone.dart';

/// Les hauteurs communes aux trois zones : leurs lignes s'alignent parce
/// qu'elles les partagent, y compris avec le texte agrandi.
class CoteGridHeights {
  final double scale;

  const CoteGridHeights(this.scale);

  double get header => AppDimensions.coteRowHeader * scale;
  double get group => AppDimensions.coteRowGroup * scale;
  double get domain => AppDimensions.coteRowDomain * scale;
  double get course => AppDimensions.coteRowCourse * scale;
  double get cell => AppDimensions.minTouchTarget * scale;
  double get maxima => AppDimensions.coteRowMaxima * scale;
  double get total => AppDimensions.coteRowTotal * scale;
  double get percent => AppDimensions.coteRowPercent * scale;
}

/// Tout ce que les trois zones se partagent.
class CoteGridContext {
  final CoteClasse classe;
  final List<CoteColumn> columns;
  final List<CoteColumn> year;
  final List<CoteCours> cours;
  final List<CoteGridRow> rows;
  final String studentId;
  final CoteGridMetrics metrics;
  final CoteGridHeights heights;
  final CoteFocusRegistry registry;
  final CoteMove enterMove;

  const CoteGridContext({
    required this.classe,
    required this.columns,
    required this.year,
    required this.cours,
    required this.rows,
    required this.studentId,
    required this.metrics,
    required this.heights,
    required this.registry,
    required this.enterMove,
  });

  /// Une colonne de total de groupe ? Alors une ligne « Pourcentage » par
  /// groupe, et un bandeau de groupes au-dessus de l'en-tête.
  bool get hasGroupTotals => columns.any((c) => !c.isInput);
}

/// La grille : cours figés à gauche, notes au centre, total figé à droite.
/// Toutes les hauteurs sont communes, donc aucune synchronisation de défilement
/// vertical : seule la zone centrale défile, et de côté.
class CoteGrid extends StatefulWidget {
  final CoteMove enterMove;

  const CoteGrid({super.key, required this.enterMove});

  @override
  State<CoteGrid> createState() => CoteGridState();
}

class CoteGridState extends State<CoteGrid> {
  late final CoteFocusRegistry _registry;
  late final CoteSaisieReady _opened;

  @override
  void initState() {
    super.initState();
    _opened = context.read<CoteSaisieBloc>().state as CoteSaisieReady;
    _registry = CoteFocusRegistry(
      studentId: _opened.currentId,
      cours: _orderedCours(_opened),
      columns: _opened.columns,
    );
  }

  /// L'ordre des lignes à l'écran, celui de Tab et des flèches.
  static List<CoteCours> _orderedCours(CoteSaisieReady state) => [
    for (final row in coteGridRows(state.classe.rubriques))
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final metrics = CoteGridMetrics.of(width, _opened.columns);
        final grid = CoteGridContext(
          classe: _opened.classe,
          columns: _opened.columns,
          year: _opened.year,
          cours: _opened.cours,
          rows: coteGridRows(_opened.classe.rubriques),
          studentId: _opened.currentId,
          metrics: metrics,
          heights: CoteGridHeights(scale),
          registry: _registry,
          enterMove: widget.enterMove,
        );
        final center = metrics.centerWidth(_opened.columns);
        final room = width - metrics.courseWidth - metrics.totalWidth;
        final fits = center <= room;
        return Row(
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
