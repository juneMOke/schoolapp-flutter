import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

/// [right] et [left] suivent l'ordre de lecture : au bout d'une ligne, la
/// suivante (ou la précédente).
enum CoteMove { down, up, right, left }

/// Les cellules modifiables de la grille de l'élève courant et leurs nœuds de
/// focus. Détenu par l'état de la grille, libéré avec elle.
class CoteFocusRegistry {
  final String studentId;

  /// Les cours visibles, dans l'ordre de l'écran : une rubrique repliée n'a plus
  /// de cellule où aller.
  List<CoteCours> cours;
  final List<CoteColumn> columns;
  final Map<String, FocusNode> _nodes = {};

  CoteFocusRegistry({
    required this.studentId,
    required this.cours,
    required List<CoteColumn> columns,
  }) : columns = columns.where((c) => c.isInput).toList(growable: false);

  static bool isEditable(CoteCours cours, CoteColumn column) =>
      column.isInput && !column.locked && column.appliesTo(cours);

  static String _slot(String coursId, String columnId) => '$coursId|$columnId';

  CoteCellKey keyOf(CoteCours cours, CoteColumn column) => CoteCellKey(
    studentId: studentId,
    coursId: cours.coursId,
    colonneId: column.id,
    examen: column.isExamen,
  );

  FocusNode nodeFor(CoteCours cours, CoteColumn column) => _nodes.putIfAbsent(
    _slot(cours.coursId, column.id),
    () => FocusNode(debugLabel: 'cote ${cours.branche} ${column.id}'),
  );

  /// Va à la cellule voisine ; reste sur place en bout de grille.
  void move(CoteCellKey from, CoteMove direction) {
    final row = cours.indexWhere((c) => c.coursId == from.coursId);
    final col = columns.indexWhere((c) => c.id == from.colonneId);
    if (row < 0 || col < 0) return;
    final next = switch (direction) {
      CoteMove.right => _nextInReadingOrder(row, col),
      CoteMove.left => _previousInReadingOrder(row, col),
      CoteMove.down => _nextInColumn(row, col, 1),
      CoteMove.up => _nextInColumn(row, col, -1),
    };
    next?.requestFocus();
  }

  /// Le cours de la case qui a le focus, s'il y en a une.
  String? get focusedCoursId {
    for (final MapEntry(:key, :value) in _nodes.entries) {
      if (value.hasFocus) return key.split('|').first;
    }
    return null;
  }

  /// La case qui a le focus — son cours et sa colonne —, s'il y en a une.
  ({CoteCours cours, CoteColumn column})? get focusedCell {
    for (final course in cours) {
      for (final column in columns) {
        final node = _nodes[_slot(course.coursId, column.id)];
        if (node != null && node.hasFocus) {
          return (cours: course, column: column);
        }
      }
    }
    return null;
  }

  /// La première case modifiable des [candidates], dans leur ordre.
  FocusNode? firstEditableOf(Iterable<CoteCours> candidates) {
    for (final course in candidates) {
      for (final column in columns) {
        if (isEditable(course, column)) return nodeFor(course, column);
      }
    }
    return null;
  }

  FocusNode? _nextInColumn(int row, int col, int step) {
    for (var r = row + step; r >= 0 && r < cours.length; r += step) {
      if (isEditable(cours[r], columns[col])) {
        return nodeFor(cours[r], columns[col]);
      }
    }
    return null;
  }

  FocusNode? _nextInReadingOrder(int row, int col) {
    for (var r = row; r < cours.length; r++) {
      for (var c = r == row ? col + 1 : 0; c < columns.length; c++) {
        if (isEditable(cours[r], columns[c])) {
          return nodeFor(cours[r], columns[c]);
        }
      }
    }
    return null;
  }

  FocusNode? _previousInReadingOrder(int row, int col) {
    for (var r = row; r >= 0; r--) {
      for (var c = r == row ? col - 1 : columns.length - 1; c >= 0; c--) {
        if (isEditable(cours[r], columns[c])) {
          return nodeFor(cours[r], columns[c]);
        }
      }
    }
    return null;
  }

  /// La première cellule modifiable pour laquelle [isEmpty] répond vrai, sinon
  /// la première modifiable.
  FocusNode? firstWhereEmpty(bool Function(CoteCours, CoteColumn) isEmpty) {
    FocusNode? first;
    for (final course in cours) {
      for (final column in columns) {
        if (!isEditable(course, column)) continue;
        first ??= nodeFor(course, column);
        if (isEmpty(course, column)) return nodeFor(course, column);
      }
    }
    return first;
  }

  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
  }
}
