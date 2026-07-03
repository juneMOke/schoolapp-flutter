import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';

/// BLoC de saisie des notes : flux mixte lecture (grille) + écriture (par
/// ligne).
///
/// Deux niveaux de statut coexistent :
/// - **global** (`gridStatus`) pour le chargement de la grille ;
/// - **par ligne** (`saveStatus` de chaque [NoteEleveRow]) pour la sauvegarde,
///   afin que chaque élève progresse indépendamment.
///
/// La saisie d'une ligne est d'abord **validée localement** (règle 1 : si NOTEE,
/// points requis et `0 ≤ points ≤ maxPoints`) — un échec passe la ligne en
/// erreur **sans** appel réseau. Pendant l'enregistrement, la ligne est
/// verrouillée (`saving`) : une nouvelle saisie sur la **même** ligne est
/// ignorée (anti-course), les autres lignes restant éditables.
class SaisieNotesBloc extends Bloc<SaisieNotesEvent, SaisieNotesState> {
  final GetNotesElevesUseCase _getNotesElevesUseCase;
  final SaisirNoteUseCase _saisirNoteUseCase;

  SaisieNotesBloc({
    required GetNotesElevesUseCase getNotesElevesUseCase,
    required SaisirNoteUseCase saisirNoteUseCase,
  }) : _getNotesElevesUseCase = getNotesElevesUseCase,
       _saisirNoteUseCase = saisirNoteUseCase,
       super(const SaisieNotesState()) {
    on<NotesElevesLoaded>(_onNotesElevesLoaded);
    on<NoteSaisie>(_onNoteSaisie);
  }

  Future<void> _onNotesElevesLoaded(
    NotesElevesLoaded event,
    Emitter<SaisieNotesState> emit,
  ) async {
    emit(
      state.copyWith(
        gridStatus: SaisieNotesGridStatus.loading,
        gridErrorType: SaisieNotesErrorType.none,
        gridErrorMessage: null,
        maxPoints: event.maxPoints,
        rows: const [],
      ),
    );

    final result = await _getNotesElevesUseCase(event.evaluationId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          gridStatus: SaisieNotesGridStatus.loadError,
          gridErrorType: _mapFailureToErrorType(failure),
          gridErrorMessage: failure.message,
        ),
      ),
      (notes) => emit(
        state.copyWith(
          gridStatus: SaisieNotesGridStatus.loaded,
          gridErrorType: SaisieNotesErrorType.none,
          gridErrorMessage: null,
          rows: notes
              .map((note) => NoteEleveRow(note: note))
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _onNoteSaisie(
    NoteSaisie event,
    Emitter<SaisieNotesState> emit,
  ) async {
    final current = state.rowFor(event.studentId);
    // Élève hors grille (ex. saisie avant chargement) : rien à faire.
    if (current == null) return;
    // Anti-course : la ligne est déjà en cours d'enregistrement.
    if (current.isSaving) return;

    // Validation locale (règle 1) — aucune requête réseau si invalide.
    if (!_isValidSaisie(event)) {
      emit(
        state.withRow(
          current.copyWith(
            saveStatus: RowSaveStatus.error,
            errorType: SaisieNotesErrorType.validation,
            // Erreur locale : pas de message backend à remonter.
            errorMessage: null,
          ),
        ),
      );
      return;
    }

    // Construction du corps AVANT le verrou : `forStatut` est durcie en `throw`
    // (studentId vide, incohérence statut/points). En la plaçant ici, un tel jet
    // laisse la ligne éditable (idle) au lieu de la figer en `saving`.
    final request = SaisirNoteRequest.forStatut(
      studentId: event.studentId,
      statut: event.statut,
      pointsObtenus: event.pointsObtenus,
    );

    // Verrou de la ligne. L'émission est synchrone avant le premier `await` :
    // une 2e saisie sur la même ligne verra bien `saving` et sera ignorée.
    emit(
      state.withRow(
        current.copyWith(
          saveStatus: RowSaveStatus.saving,
          errorType: SaisieNotesErrorType.none,
          errorMessage: null,
        ),
      ),
    );

    final result = await _saisirNoteUseCase(event.evaluationId, request);

    result.fold(
      (failure) {
        // On relit l'état courant : d'autres lignes ont pu évoluer entre-temps.
        final row = state.rowFor(event.studentId);
        if (row == null) return;
        emit(
          state.withRow(
            row.copyWith(
              saveStatus: RowSaveStatus.error,
              errorType: _mapFailureToErrorType(failure),
              errorMessage: failure.message,
            ),
          ),
        );
      },
      (evaluation) {
        final row = state.rowFor(event.studentId);
        if (row == null) return;
        emit(
          state.withRow(
            row.copyWith(
              // Fusionne la note persistée renvoyée par le PUT.
              note: _mergeNote(row.note, evaluation),
              saveStatus: RowSaveStatus.saved,
              errorType: SaisieNotesErrorType.none,
              errorMessage: null,
            ),
          ),
        );
      },
    );
  }

  /// Règle 1 : une saisie NOTEE exige des points non nuls dans `[0, maxPoints]`.
  /// Les autres statuts n'exigent rien ; un statut `unknown` est refusé.
  bool _isValidSaisie(NoteSaisie event) {
    if (event.statut == StatutNote.unknown) return false;
    if (event.statut != StatutNote.notee) return true;
    final points = event.pointsObtenus;
    if (points == null) return false;
    return points >= 0 && points <= state.maxPoints;
  }

  /// Conserve l'identité de l'élève et applique la note persistée renvoyée.
  NoteEleve _mergeNote(NoteEleve base, NoteEvaluation evaluation) => NoteEleve(
    studentId: base.studentId,
    firstName: base.firstName,
    lastName: base.lastName,
    middleName: base.middleName,
    pointsObtenus: evaluation.pointsObtenus,
    statut: evaluation.statut,
  );

  SaisieNotesErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => SaisieNotesErrorType.network,
        NotFoundFailure() => SaisieNotesErrorType.notFound,
        ValidationFailure() => SaisieNotesErrorType.validation,
        // Convention projet (cf. interceptor Dio) : HTTP 403 ->
        // UnauthorizedFailure -> forbidden ; HTTP 401 ->
        // InvalidCredentialsFailure -> invalidCredentials.
        UnauthorizedFailure() => SaisieNotesErrorType.forbidden,
        InvalidCredentialsFailure() => SaisieNotesErrorType.invalidCredentials,
        ServerFailure() => SaisieNotesErrorType.server,
        StorageFailure() => SaisieNotesErrorType.storage,
        AuthFailure() => SaisieNotesErrorType.auth,
        _ => SaisieNotesErrorType.unknown,
      };
}
