import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

enum CoteMove { down, up, right }

/// Les cellules modifiables de la grille de l'élève courant et leurs nœuds de
/// focus. Détenu par l'état de la grille, libéré avec elle.
class CoteFocusRegistry {
  final String studentId;
  final List<CoteCours> cours;
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
    final next = direction == CoteMove.right
        ? _nextInReadingOrder(row, col)
        : _nextInColumn(row, col, direction == CoteMove.down ? 1 : -1);
    next?.requestFocus();
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
