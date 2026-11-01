import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';

/// Les totaux d'un cours pour un élève, en centièmes.
class CoteCoursCalc extends Equatable {
  final int total;
  final int maxFilled;
  final int maxScope;

  const CoteCoursCalc({
    required this.total,
    required this.maxFilled,
    required this.maxScope,
  });

  /// Pourcentage entier sur les maxima remplis ; `null` si rien n'est rempli.
  int? get pct => roundedPercent(total, maxFilled);

  @override
  List<Object?> get props => [total, maxFilled, maxScope];
}

/// Le bulletin d'un élève sur la portée. Le pourcentage est **provisoire** tant
/// que tout n'est pas rempli : il porte sur les maxima remplis, pas sur le
/// maximum complet, sinon un examen manquant ferait chuter 61/80 à 38 %.
class CoteEleveCalc extends Equatable {
  final int total;
  final int maxFilled;
  final int maxScope;
  final int filled;
  final int cells;
  final int invalid;
  final Map<String, CoteCoursCalc> cours;

  const CoteEleveCalc({
    required this.total,
    required this.maxFilled,
    required this.maxScope,
    required this.filled,
    required this.cells,
    required this.invalid,
    required this.cours,
  });

  int? get pct => roundedPercent(total, maxFilled);

  /// En centièmes de pour-cent : la grandeur que compare le rang.
  int? get pctHundredths => maxFilled == 0
      ? null
      : (2 * total * 10000 + maxFilled) ~/ (2 * maxFilled);

  bool get complete => filled == cells && invalid == 0;
  bool get provisoire => filled < cells;

  @override
  List<Object?> get props => [
    total,
    maxFilled,
    maxScope,
    filled,
    cells,
    invalid,
    cours,
  ];
}

/// La place de chaque élève classé, et combien le sont.
class CoteRanking extends Equatable {
  final Map<String, int> rangs;
  final int classes;

  const CoteRanking({required this.rangs, required this.classes});

  @override
  List<Object?> get props => [rangs, classes];
}

class CoteProgress extends Equatable {
  final int filled;
  final int cells;
  final int complets;

  const CoteProgress({
    required this.filled,
    required this.cells,
    required this.complets,
  });

  @override
  List<Object?> get props => [filled, cells, complets];
}

/// Arrondi au plus proche, .5 vers le haut ; `null` sans maximum.
int? roundedPercent(int total, int max) =>
    max == 0 ? null : (2 * total * 100 + max) ~/ (2 * max);

/// Le calcul de l'écran : fonctions pures, sans dépendance Flutter. Le serveur
/// refait le sien et fait foi pour le bulletin.
class CoteCalculator {
  const CoteCalculator();

  /// [columns] : les colonnes de la portée, totaux de groupe ignorés.
  CoteEleveCalc calcEleve({
    required String studentId,
    required List<CoteCours> cours,
    required List<CoteColumn> columns,
    required CoteCellTable cells,
  }) {
    var total = 0, maxFilled = 0, maxScope = 0;
    var filled = 0, expected = 0, invalid = 0;
    final parCours = <String, CoteCoursCalc>{};
    final inputs = columns.where((c) => c.isInput).toList(growable: false);
    for (final course in cours) {
      var courseTotal = 0, courseFilled = 0, courseScope = 0;
      for (final column in inputs) {
        if (!column.appliesTo(course)) continue;
        expected++;
        final max = column.maxFor(course) * 100;
        courseScope += max;
        final cell = cells.cell(studentId, course.coursId, column.id);
        if (cell != null && cell.isInvalid) invalid++;
        final value = cell?.countedValue;
        if (value == null) continue;
        filled++;
        courseTotal += toCentis(value);
        courseFilled += max;
      }
      total += courseTotal;
      maxFilled += courseFilled;
      maxScope += courseScope;
      parCours[course.coursId] = CoteCoursCalc(
        total: courseTotal,
        maxFilled: courseFilled,
        maxScope: courseScope,
      );
    }
    return CoteEleveCalc(
      total: total,
      maxFilled: maxFilled,
      maxScope: maxScope,
      filled: filled,
      cells: expected,
      invalid: invalid,
      cours: parCours,
    );
  }

  /// La somme d'une colonne sur des cours, en centièmes. Un total de groupe
  /// additionne les colonnes saisies de son groupe.
  int columnSum({
    required String studentId,
    required Iterable<CoteCours> cours,
    required CoteColumn column,
    required List<CoteColumn> year,
    required CoteCellTable cells,
  }) {
    final sources = column.isInput
        ? [column]
        : year.where((c) => c.isInput && c.periodeId == column.periodeId);
    var sum = 0;
    for (final course in cours) {
      for (final source in sources) {
        if (!source.appliesTo(course)) continue;
        final value = cells
            .cell(studentId, course.coursId, source.id)
            ?.countedValue;
        if (value != null) sum += toCentis(value);
      }
    }
    return sum;
  }

  /// Le maximum d'une colonne sur des cours, en points.
  int columnMax(Iterable<CoteCours> cours, CoteColumn column) => cours
      .where(column.appliesTo)
      .fold(0, (sum, course) => sum + column.maxFor(course));

  /// Le rang compare le pourcentage à 2 décimales, comme le bulletin : mêmes
  /// ex æquo. Sans aucune note, l'élève n'est pas classé.
  CoteRanking rank(Map<String, CoteEleveCalc> calcs) {
    final classes = <(String, int)>[
      for (final entry in calcs.entries)
        if (entry.value.filled > 0 && entry.value.pctHundredths != null)
          (entry.key, entry.value.pctHundredths!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final rangs = <String, int>{};
    for (var i = 0; i < classes.length; i++) {
      final tied = i > 0 && classes[i].$2 == classes[i - 1].$2;
      rangs[classes[i].$1] = tied ? rangs[classes[i - 1].$1]! : i + 1;
    }
    return CoteRanking(rangs: rangs, classes: classes.length);
  }

  CoteProgress progress(Iterable<CoteEleveCalc> calcs) {
    var filled = 0, cells = 0, complets = 0;
    for (final calc in calcs) {
      filled += calc.filled;
      cells += calc.cells;
      if (calc.cells > 0 && calc.complete) complets++;
    }
    return CoteProgress(filled: filled, cells: cells, complets: complets);
  }
}
