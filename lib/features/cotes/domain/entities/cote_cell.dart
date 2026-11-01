import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Une cellule : (élève, cours, colonne). [colonneId] est une sous-période, ou
/// la période de l'examen quand [examen] est vrai.
class CoteCellKey extends Equatable {
  final String studentId;
  final String coursId;
  final String colonneId;
  final bool examen;

  const CoteCellKey({
    required this.studentId,
    required this.coursId,
    required this.colonneId,
    required this.examen,
  });

  @override
  List<Object?> get props => [studentId, coursId, colonneId, examen];
}

/// L'état d'une cellule. Trois sources s'y superposent :
///
/// - [serverCote] et [calculee], ce que le serveur a dit au dernier chargement ;
/// - le **brouillon** ([hasDraft], [draftValue]), la dernière saisie valide
///   encore à envoyer — ou refusée, et gardée telle quelle ([syncState]) ;
/// - [invalidRaw], une frappe hors barème : affichée, jamais envoyée.
///
/// Un brouillon à `null` est une cote vidée : la colonne revient au calcul tout
/// de suite, sans attendre l'accusé.
class CoteCell extends Equatable {
  final CoteCellKey key;
  final double? serverCote;
  final double? calculee;
  final int? serverUpdatedAtMs;
  final bool hasDraft;
  final double? draftValue;
  final int? draftUpdatedAtMs;
  final SyncState syncState;
  final String? rejectionReason;
  final String? invalidRaw;

  const CoteCell({
    required this.key,
    this.serverCote,
    this.calculee,
    this.serverUpdatedAtMs,
    this.hasDraft = false,
    this.draftValue,
    this.draftUpdatedAtMs,
    this.syncState = SyncState.synced,
    this.rejectionReason,
    this.invalidRaw,
  });

  bool get isRejected => syncState == SyncState.syncError;

  /// À corriger : hors barème, ou refusée par le serveur.
  bool get isInvalid => invalidRaw != null || isRejected;

  /// La valeur montrée, avant toute frappe invalide.
  double? get displayedValue =>
      hasDraft ? (draftValue ?? calculee) : (serverCote ?? calculee);

  /// Vrai si la valeur montrée vient des évaluations.
  bool get isCalculated =>
      (hasDraft ? draftValue : serverCote) == null && calculee != null;

  /// Ce qui entre dans les totaux : rien pour une cellule à corriger.
  double? get countedValue => isInvalid ? null : displayedValue;

  @override
  List<Object?> get props => [
    key,
    serverCote,
    calculee,
    serverUpdatedAtMs,
    hasDraft,
    draftValue,
    draftUpdatedAtMs,
    syncState,
    rejectionReason,
    invalidRaw,
  ];
}

/// Les cellules d'une classe, rangées par élève : une frappe ne recopie que les
/// cellules de cet élève.
class CoteCellTable {
  final Map<String, Map<String, CoteCell>> _byStudent;

  const CoteCellTable._(this._byStudent);

  const CoteCellTable.empty() : _byStudent = const {};

  factory CoteCellTable.of(Iterable<CoteCell> cells) {
    final byStudent = <String, Map<String, CoteCell>>{};
    for (final cell in cells) {
      (byStudent[cell.key.studentId] ??= {})[_slot(
            cell.key.coursId,
            cell.key.colonneId,
          )] =
          cell;
    }
    return CoteCellTable._(byStudent);
  }

  static String _slot(String coursId, String colonneId) =>
      '$coursId|$colonneId';

  CoteCell? cell(String studentId, String coursId, String colonneId) =>
      _byStudent[studentId]?[_slot(coursId, colonneId)];

  CoteCellTable withCell(CoteCell cell) {
    final studentId = cell.key.studentId;
    return CoteCellTable._({
      ..._byStudent,
      studentId: {
        ...?_byStudent[studentId],
        _slot(cell.key.coursId, cell.key.colonneId): cell,
      },
    });
  }

  Iterable<CoteCell> get all => _byStudent.values.expand((m) => m.values);
}
