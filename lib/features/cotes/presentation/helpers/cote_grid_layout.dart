import 'dart:ui';

import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

/// Les largeurs de la grille pour une largeur reçue et un jeu de colonnes.
class CoteGridMetrics {
  final double courseWidth;
  final double noteWidth;
  final double groupWidth;
  final double totalWidth;
  final bool phone;
  final bool dense;

  const CoteGridMetrics._({
    required this.courseWidth,
    required this.noteWidth,
    required this.groupWidth,
    required this.totalWidth,
    required this.phone,
    required this.dense,
  });

  factory CoteGridMetrics.of(double width, List<CoteColumn> columns) {
    final count = columns.length;
    final dense = count > 6;
    final phone = width < AppBreakpoints.coteGridPhoneMax;
    final compact = width < AppBreakpoints.coteGridCompactMax;
    return CoteGridMetrics._(
      courseWidth: phone
          ? AppDimensions.coteCourseColumnPhone
          : dense || compact
          ? AppDimensions.coteCourseColumnDense
          : AppDimensions.coteCourseColumn,
      noteWidth: count <= 4
          ? AppDimensions.coteNoteColumn
          : dense
          ? AppDimensions.coteNoteColumnDense
          : AppDimensions.coteNoteColumnMedium,
      groupWidth: dense
          ? AppDimensions.coteGroupColumnDense
          : AppDimensions.coteGroupColumn,
      totalWidth: phone
          ? AppDimensions.coteTotalColumnPhone
          : dense
          ? AppDimensions.coteTotalColumnDense
          : AppDimensions.coteTotalColumn,
      phone: phone,
      dense: dense,
    );
  }

  double widthOf(CoteColumn column) => column.isInput ? noteWidth : groupWidth;

  double centerWidth(List<CoteColumn> columns) =>
      columns.fold(0, (sum, column) => sum + widthOf(column));

  /// Sous cette largeur, la zone des notes défile de côté.
  double minGridWidth(List<CoteColumn> columns) =>
      courseWidth + centerWidth(columns) + totalWidth;
}

/// La liste des élèves n'est montrée que si la grille tient à côté, sans
/// défilement. Une fois masquée, elle attend [AppDimensions.coteListHysteresis]
/// de marge pour revenir.
bool coteListVisible({
  required double width,
  required List<CoteColumn> columns,
  required bool wasVisible,
}) {
  if (width < AppBreakpoints.coteGridCompactMax) return false;
  final gridWidth =
      width - AppDimensions.coteListPanelWidth - AppDimensions.coteListGap;
  final needed = CoteGridMetrics.of(gridWidth, columns).minGridWidth(columns);
  return gridWidth >=
      needed + (wasVisible ? 0 : AppDimensions.coteListHysteresis);
}

/// La teinte d'un domaine du bulletin, par rotation.
class CoteTone {
  final Color ink;
  final Color soft;

  const CoteTone(this.ink, this.soft);
}

const List<CoteTone> _tones = [
  CoteTone(AppColors.bleuArdoise, AppColors.bleuArdoiseSoft),
  CoteTone(AppColors.terreCuite, AppColors.coteDomainTerreSoft),
  CoteTone(AppColors.vertSavane, AppColors.coteDomainVertSoft),
  CoteTone(AppColors.coteDomainPrune, AppColors.coteDomainPruneSoft),
];

/// Une ligne de la grille.
sealed class CoteGridRow {
  final CoteTone tone;

  const CoteGridRow(this.tone);
}

/// Un domaine ou un sous-domaine. Il porte ses sous-totaux si le barème le dit.
final class CoteRubriqueRow extends CoteGridRow {
  final CoteRubrique rubrique;
  final int depth;

  const CoteRubriqueRow(this.rubrique, this.depth, CoteTone tone) : super(tone);
}

final class CoteCourseRow extends CoteGridRow {
  final CoteCours cours;

  const CoteCourseRow(this.cours, CoteTone tone) : super(tone);
}

/// L'arbre du barème mis à plat, dans l'ordre du bulletin. Un nœud sans libellé
/// (grille plate) n'a pas de ligne : ses cours passent directement.
List<CoteGridRow> coteGridRows(List<CoteRubrique> rubriques) {
  final rows = <CoteGridRow>[];

  void visit(CoteRubrique rubrique, int depth, CoteTone tone) {
    final label = rubrique.label;
    final labelled = label != null && label.trim().isNotEmpty;
    if (labelled) rows.add(CoteRubriqueRow(rubrique, depth, tone));
    for (final cours in rubrique.cours) {
      rows.add(CoteCourseRow(cours, tone));
    }
    for (final sous in rubrique.sousRubriques) {
      visit(sous, labelled ? depth + 1 : depth, tone);
    }
  }

  for (var i = 0; i < rubriques.length; i++) {
    visit(rubriques[i], 0, _tones[i % _tones.length]);
  }
  return rows;
}

/// La couleur d'un pourcentage : rouge sous 50, vert dès 70.
Color cotePercentColor(int? percent) {
  if (percent == null) return AppColors.textMuted;
  if (percent < 50) return AppColors.error;
  if (percent >= 70) return AppColors.vertSavane;
  return AppColors.bleuArdoise;
}
