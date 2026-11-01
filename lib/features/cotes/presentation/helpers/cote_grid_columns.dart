import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

/// Une colonne affichée. Le bulletin fait précéder les notes de leur maximum :
/// ces colonnes-là n'existent qu'à l'écran. Le calcul, le focus et les portées
/// ne connaissent que les [CoteColumn].
class CoteGridColumn {
  final CoteColumn source;
  final bool isMax;

  const CoteGridColumn.value(this.source) : isMax = false;

  const CoteGridColumn.max(this.source) : isMax = true;
}

/// Les colonnes dans l'ordre du bulletin : un seul maximum pour les périodes
/// voisines d'un même groupe, puis un devant l'examen et un devant le total.
List<CoteGridColumn> coteGridColumns(List<CoteColumn> columns) {
  final result = <CoteGridColumn>[];
  CoteColumn? previous;
  for (final column in columns) {
    final samePeriodBlock =
        column.kind == CoteColumnKind.periode &&
        previous?.kind == CoteColumnKind.periode &&
        previous?.periodeId == column.periodeId;
    if (!samePeriodBlock) result.add(CoteGridColumn.max(column));
    result.add(CoteGridColumn.value(column));
    previous = column;
  }
  return result;
}
