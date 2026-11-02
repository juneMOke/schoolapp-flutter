import 'dart:ui';

import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';

/// Les largeurs de la grille pour une largeur reçue et un jeu de colonnes.
class CoteGridMetrics {
  final double courseWidth;
  final double minCourseWidth;
  final double noteWidth;
  final double groupWidth;
  final double maxWidth;
  final double totalWidth;
  final double centerWidth;
  final bool phone;
  final bool dense;

  const CoteGridMetrics._({
    required this.courseWidth,
    required this.minCourseWidth,
    required this.noteWidth,
    required this.groupWidth,
    required this.maxWidth,
    required this.totalWidth,
    required this.centerWidth,
    required this.phone,
    required this.dense,
  });

  /// [textScale] : les colonnes de chiffres grandissent avec le texte, sinon un
  /// « 119,75 » n'y tient plus à ×1,3. Celle des cours va à la ligne, et prend
  /// le surplus de largeur jusqu'à [AppDimensions.coteCourseColumnMax].
  factory CoteGridMetrics.of(
    double width,
    List<CoteColumn> columns, {
    double textScale = 1,
  }) {
    final count = columns.length;
    final dense = count > 6;
    final phone = width < AppBreakpoints.coteGridPhoneMax;
    final compact = width < AppBreakpoints.coteGridCompactMax;
    final minCourseWidth = phone
        ? AppDimensions.coteCourseColumnPhone
        : dense || compact
        ? AppDimensions.coteCourseColumnDense
        : AppDimensions.coteCourseColumn;
    final noteWidth =
        textScale *
        (count <= 4 && !phone
            ? AppDimensions.coteNoteColumn
            : dense
            ? AppDimensions.coteNoteColumnDense
            : AppDimensions.coteNoteColumnMedium);
    final groupWidth =
        textScale *
        (dense
            ? AppDimensions.coteGroupColumnDense
            : AppDimensions.coteGroupColumn);
    final maxWidth =
        textScale *
        (dense || phone
            ? AppDimensions.coteMaxColumnDense
            : AppDimensions.coteMaxColumn);
    final totalWidth =
        textScale *
        (phone
            ? AppDimensions.coteTotalColumnPhone
            : dense
            ? AppDimensions.coteTotalColumnDense
            : AppDimensions.coteTotalColumn);
    final centerWidth = coteGridColumns(columns).fold<double>(0, (sum, column) {
      if (column.isMax) return sum + maxWidth;
      return sum + (column.source.isInput ? noteWidth : groupWidth);
    });
    final room = width - centerWidth - totalWidth;
    return CoteGridMetrics._(
      courseWidth: room.clamp(
        minCourseWidth,
        AppDimensions.coteCourseColumnMax,
      ),
      minCourseWidth: minCourseWidth,
      noteWidth: noteWidth,
      groupWidth: groupWidth,
      maxWidth: maxWidth,
      totalWidth: totalWidth,
      centerWidth: centerWidth,
      phone: phone,
      dense: dense,
    );
  }

  double widthOf(CoteGridColumn column) {
    if (column.isMax) return maxWidth;
    return column.source.isInput ? noteWidth : groupWidth;
  }

  /// Sous cette largeur, la zone des notes défile de côté.
  double get minGridWidth => minCourseWidth + centerWidth + totalWidth;
}

/// La liste des élèves n'est montrée que si la grille tient à côté, sans
/// défilement. Une fois masquée, elle attend [AppDimensions.coteListHysteresis]
/// de marge pour revenir.
bool coteListVisible({
  required double width,
  required List<CoteColumn> columns,
  required bool wasVisible,
  double textScale = 1,
}) {
  if (width < AppBreakpoints.coteGridCompactMax) return false;
  final gridWidth =
      width - AppDimensions.coteListPanelWidth - AppDimensions.coteListGap;
  final needed = CoteGridMetrics.of(
    gridWidth,
    columns,
    textScale: textScale,
  ).minGridWidth;
  return gridWidth >=
      needed + (wasVisible ? 0 : AppDimensions.coteListHysteresis);
}

/// La teinte d'un domaine du bulletin, par rotation.
class CoteTone {
  final Color ink;
  final Color soft;

  /// [ink] assombrie au besoin : le fond d'un bandeau, texte clair dessus.
  final Color strong;

  const CoteTone(this.ink, this.soft, {Color? strong}) : strong = strong ?? ink;

  /// Une ligne sur deux : à peine teintée, les cases blanches s'en détachent.
  Color get wash => soft.withValues(alpha: 0.5);
}

const List<CoteTone> _tones = [
  CoteTone(AppColors.bleuArdoise, AppColors.bleuArdoiseSoft),
  CoteTone(
    AppColors.terreCuite,
    AppColors.coteDomainTerreSoft,
    strong: AppColors.terreCuiteDark,
  ),
  CoteTone(AppColors.vertSavane, AppColors.coteDomainVertSoft),
  CoteTone(AppColors.coteDomainPrune, AppColors.coteDomainPruneSoft),
];

/// Une ligne de la grille.
sealed class CoteGridRow {
  final CoteTone tone;

  const CoteGridRow(this.tone);

  /// Stable d'un pliage à l'autre.
  String get id;
}

/// Le titre d'un domaine (profondeur 0) ou d'une branche. Il ne porte aucun
/// chiffre : ils sont sur la ligne de sous-total qui le referme.
final class CoteRubriqueRow extends CoteGridRow {
  final CoteRubrique rubrique;
  final int depth;
  final bool collapsed;

  const CoteRubriqueRow(
    this.rubrique,
    this.depth,
    CoteTone tone, {
    this.collapsed = false,
  }) : super(tone);

  bool get isDomain => depth == 0;

  @override
  String get id => 'titre|${rubrique.id}';
}

final class CoteCourseRow extends CoteGridRow {
  final CoteCours cours;

  /// Une ligne sur deux dans sa rubrique.
  final bool shaded;

  const CoteCourseRow(this.cours, CoteTone tone, {this.shaded = false})
    : super(tone);

  @override
  String get id => 'cours|${cours.coursId}';
}

/// La ligne qui referme une rubrique : la somme de chaque colonne.
final class CoteSubtotalRow extends CoteGridRow {
  final CoteRubrique rubrique;

  const CoteSubtotalRow(this.rubrique, CoteTone tone) : super(tone);

  @override
  String get id => 'sous-total|${rubrique.id}';
}

/// Une rubrique se referme sur un sous-total dès qu'elle a plusieurs cours à
/// elle, ou que le barème le demande pour ce qu'elle regroupe. Jamais pour un
/// cours seul, ni pour répéter la ligne de son unique branche.
bool _closesWithSubtotal(CoteRubrique rubrique) {
  final label = rubrique.label;
  if (label == null || label.trim().isEmpty) return false;
  if (rubrique.allCours.length < 2) return false;
  if (rubrique.cours.isEmpty &&
      rubrique.sousRubriques.length == 1 &&
      _closesWithSubtotal(rubrique.sousRubriques.single)) {
    return false;
  }
  return rubrique.cours.length > 1 || rubrique.produitSousTotal;
}

/// L'arbre du barème mis à plat, dans l'ordre du bulletin. Un nœud sans libellé
/// (grille plate) n'a pas de ligne : ses cours passent directement. Une rubrique
/// de [collapsed] se réduit à son titre et à sa somme.
List<CoteGridRow> coteGridRows(
  List<CoteRubrique> rubriques, {
  Set<String> collapsed = const {},
}) {
  final rows = <CoteGridRow>[];

  void visit(CoteRubrique rubrique, int depth, CoteTone tone) {
    final label = rubrique.label;
    final labelled = label != null && label.trim().isNotEmpty;
    final folded = labelled && collapsed.contains(rubrique.id);
    if (labelled) {
      rows.add(CoteRubriqueRow(rubrique, depth, tone, collapsed: folded));
    }
    if (folded) {
      rows.add(CoteSubtotalRow(rubrique, tone));
      return;
    }
    for (var i = 0; i < rubrique.cours.length; i++) {
      rows.add(CoteCourseRow(rubrique.cours[i], tone, shaded: i.isOdd));
    }
    for (final sous in rubrique.sousRubriques) {
      visit(sous, labelled ? depth + 1 : depth, tone);
    }
    if (_closesWithSubtotal(rubrique)) {
      rows.add(CoteSubtotalRow(rubrique, tone));
    }
  }

  for (var i = 0; i < rubriques.length; i++) {
    visit(rubriques[i], 0, _tones[i % _tones.length]);
  }
  return rows;
}

/// Un score sous la moitié du maximum. Comparé sur les points, pas sur un
/// pourcentage arrondi : 9,9/20 échoue. Sans maximum, rien à juger.
bool coteScoreFails(int obtained, int max) => max > 0 && obtained * 2 < max;

/// L'encre d'un score : rouge sous la moitié du maximum, vert dès la moitié.
/// `null` sans maximum : rien à juger.
Color? coteScoreInk(int obtained, int max) {
  if (max <= 0) return null;
  return coteScoreFails(obtained, max) ? AppColors.error : AppColors.vertSavane;
}

/// La marque d'un score sous la moitié : souligné, comme au bulletin papier.
/// Le rouge seul ne se lit ni par un daltonien ni sur une impression en gris.
TextDecoration coteScoreMark(int obtained, int max) =>
    coteScoreFails(obtained, max)
    ? TextDecoration.underline
    : TextDecoration.none;
