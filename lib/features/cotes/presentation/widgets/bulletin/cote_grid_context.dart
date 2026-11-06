import 'package:flutter/foundation.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';

/// Les hauteurs communes aux trois zones : leurs lignes s'alignent parce
/// qu'elles les partagent, y compris avec le texte agrandi.
class CoteGridHeights {
  final double scale;

  /// Sur téléphone, les titres passent sur deux lignes plutôt que de se couper.
  final bool phone;

  const CoteGridHeights(this.scale, {this.phone = false});

  double get header => AppDimensions.coteRowHeader * scale;
  double get group => AppDimensions.coteRowGroup * scale;
  double get domain =>
      (phone ? AppDimensions.coteRowDomainPhone : AppDimensions.coteRowDomain) *
      scale;
  double get branch => AppDimensions.coteRowBranch * scale;
  double get subtotal => AppDimensions.coteRowSubtotal * scale;
  double get course => AppDimensions.coteRowCourse * scale;
  double get cell => AppDimensions.minTouchTarget * scale;
  double get maxima => AppDimensions.coteRowMaxima * scale;
  double get total => AppDimensions.coteRowTotal * scale;
  double get percent => AppDimensions.coteRowPercent * scale;

  double of(CoteGridRow row) => switch (row) {
    final CoteRubriqueRow r => r.isDomain ? domain : branch,
    CoteCourseRow() => course,
    CoteSubtotalRow() => subtotal,
  };
}

/// Tout ce que les trois zones se partagent.
class CoteGridContext {
  final CoteClasse classe;
  final List<CoteColumn> columns;
  final List<CoteGridColumn> gridColumns;
  final List<CoteColumn> year;
  final List<CoteCours> cours;
  final List<CoteGridRow> rows;
  final String studentId;
  final CoteGridMetrics metrics;
  final CoteGridHeights heights;
  final CoteFocusRegistry registry;
  final CoteMove enterMove;

  /// Le cours survolé : les trois zones d'une ligne s'éclairent ensemble.
  final ValueNotifier<String?> hoveredCours;

  /// La hauteur de la bande d'aide qui flotte en bas de la page : la case qui
  /// prend le focus se montre au-dessus d'elle, pas dessous.
  final ValueNotifier<double> hintBandHeight;
  final ValueChanged<String> onToggleRubrique;

  const CoteGridContext({
    required this.classe,
    required this.columns,
    required this.gridColumns,
    required this.year,
    required this.cours,
    required this.rows,
    required this.studentId,
    required this.metrics,
    required this.heights,
    required this.registry,
    required this.enterMove,
    required this.hoveredCours,
    required this.hintBandHeight,
    required this.onToggleRubrique,
  });

  /// Une colonne de total de groupe ? Alors une ligne « Pourcentage » par
  /// groupe, et un bandeau de groupes au-dessus de l'en-tête.
  bool get hasGroupTotals => columns.any((c) => !c.isInput);

  double get rowsTop => (hasGroupTotals ? heights.group : 0) + heights.header;
}
