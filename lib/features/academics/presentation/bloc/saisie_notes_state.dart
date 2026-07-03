import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';

/// Statut global du chargement de la grille.
enum SaisieNotesGridStatus { initial, loading, loaded, loadError }

/// Statut de sauvegarde **d'une ligne** (indépendant du statut global).
enum RowSaveStatus { idle, saving, saved, error }

/// Type d'erreur exposé au UI (chargement global **ou** sauvegarde par ligne),
/// aligné sur la convention du module (cf. `CreateEvaluationErrorType`).
enum SaisieNotesErrorType {
  none,
  network,
  notFound,
  validation,
  // HTTP 403 -> UnauthorizedFailure -> forbidden (convention projet).
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans les
/// `copyWith` (convention projet pour les champs nullable).
const _undefined = Object();

/// Une ligne de la grille : l'entité [NoteEleve] (identité + note persistée,
/// mise à jour après un enregistrement réussi) + son propre [saveStatus] et son
/// erreur éventuelle.
class NoteEleveRow extends Equatable {
  final NoteEleve note;
  final RowSaveStatus saveStatus;
  final SaisieNotesErrorType errorType;

  /// Message d'erreur remonté pour cette ligne (corps backend si présent). Null
  /// hors échec réseau (les erreurs de validation locale n'en portent pas).
  final String? errorMessage;

  const NoteEleveRow({
    required this.note,
    this.saveStatus = RowSaveStatus.idle,
    this.errorType = SaisieNotesErrorType.none,
    this.errorMessage,
  });

  String get studentId => note.studentId;

  bool get isSaving => saveStatus == RowSaveStatus.saving;

  NoteEleveRow copyWith({
    NoteEleve? note,
    RowSaveStatus? saveStatus,
    SaisieNotesErrorType? errorType,
    Object? errorMessage = _undefined,
  }) => NoteEleveRow(
    note: note ?? this.note,
    saveStatus: saveStatus ?? this.saveStatus,
    errorType: errorType ?? this.errorType,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  @override
  List<Object?> get props => [note, saveStatus, errorType, errorMessage];
}

/// État de la saisie des notes : un statut **global** de chargement de la grille
/// + un statut **par ligne** (porté par chaque [NoteEleveRow]).
class SaisieNotesState extends Equatable {
  final SaisieNotesGridStatus gridStatus;
  final SaisieNotesErrorType gridErrorType;

  /// Message d'erreur du chargement de la grille (corps backend si présent).
  final String? gridErrorMessage;

  /// Barème de l'évaluation, transmis au chargement, pour la validation locale.
  final double maxPoints;

  final List<NoteEleveRow> rows;

  const SaisieNotesState({
    this.gridStatus = SaisieNotesGridStatus.initial,
    this.gridErrorType = SaisieNotesErrorType.none,
    this.gridErrorMessage,
    this.maxPoints = 0,
    this.rows = const [],
  });

  SaisieNotesState copyWith({
    SaisieNotesGridStatus? gridStatus,
    SaisieNotesErrorType? gridErrorType,
    Object? gridErrorMessage = _undefined,
    double? maxPoints,
    List<NoteEleveRow>? rows,
  }) => SaisieNotesState(
    gridStatus: gridStatus ?? this.gridStatus,
    gridErrorType: gridErrorType ?? this.gridErrorType,
    gridErrorMessage: identical(gridErrorMessage, _undefined)
        ? this.gridErrorMessage
        : gridErrorMessage as String?,
    maxPoints: maxPoints ?? this.maxPoints,
    rows: rows ?? this.rows,
  );

  /// La ligne de l'élève [studentId], ou `null` si absente de la grille.
  NoteEleveRow? rowFor(String studentId) {
    for (final row in rows) {
      if (row.studentId == studentId) return row;
    }
    return null;
  }

  /// Remplace la ligne de même `studentId` que [row] (les autres inchangées).
  SaisieNotesState withRow(NoteEleveRow row) => copyWith(
    rows: rows
        .map((r) => r.studentId == row.studentId ? row : r)
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [
    gridStatus,
    gridErrorType,
    gridErrorMessage,
    maxPoints,
    rows,
  ];
}
