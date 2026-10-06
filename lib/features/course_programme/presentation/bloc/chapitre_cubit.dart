import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_children_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_change_source.dart';

/// Le détail d'un chapitre : lecture locale relue à chaque signal, et ses
/// gestes — statut rapide, objectif coché, contenu rédigé (la fiche part
/// entière), notes de séance.
///
/// Statut et objectif sont **optimistes** : l'écran bouge tout de suite ; un
/// échec d'écriture locale relit l'état gardé et le dit.
///
/// Supprimer une note la masque d'abord : le geste ne part qu'après
/// [undoWindow], sauf annulation. Quitter l'écran ne l'annule pas.
class ChapitreCubit extends Cubit<ChapitreState> {
  final String chapitreId;
  final LoadChapitreUseCase _load;
  final SaveChapitreUseCase _save;
  final AddChapitreNoteUseCase _addNote;
  final DeleteChapitreNoteUseCase _deleteNote;
  final OpenChapitreDocumentUseCase _openDocument;
  final ProgrammeChangeSource _source;
  final Duration undoWindow;
  final Map<String, Timer> _pendingDeletions = {};
  void Function()? _unwatch;
  var _seq = 0;

  ChapitreCubit({
    required this.chapitreId,
    required LoadChapitreUseCase load,
    required SaveChapitreUseCase save,
    required AddChapitreNoteUseCase addNote,
    required DeleteChapitreNoteUseCase deleteNote,
    required OpenChapitreDocumentUseCase openDocument,
    required ProgrammeChangeSource source,
    required this.undoWindow,
  }) : _load = load,
       _save = save,
       _addNote = addNote,
       _deleteNote = deleteNote,
       _openDocument = openDocument,
       _source = source,
       super(const ChapitreState());

  Future<void> load() async {
    emit(const ChapitreState());
    await refresh();
    _unwatch ??= _source.watch(() => unawaited(refresh()));
  }

  /// Relecture : un échec ne remplace jamais un chapitre affiché.
  Future<void> refresh() async {
    final result = await _load(chapitreId);
    if (isClosed) return;
    result.fold(
      (_) {
        if (state.detail == null) {
          emit(state.copyWith(status: ChapitreStatus.failure));
        }
      },
      (detail) =>
          emit(state.copyWith(status: ChapitreStatus.ready, detail: detail)),
    );
  }

  Future<void> setStatut(ChapitreStatut statut) =>
      _saveFiche((chapitre) => chapitre.copyWith(statut: statut));

  Future<void> toggleObjectif(String objectifId) => _saveFiche(
    (chapitre) => chapitre.copyWith(
      objectifs: [
        for (final o in chapitre.objectifs)
          o.id == objectifId ? o.copyWith(atteint: !o.atteint) : o,
      ],
    ),
  );

  /// Enregistre le contenu rédigé ; les blocs vides ne sont pas gardés.
  Future<bool> saveBlocs(List<ChapitreBloc> blocs, {bool announce = true}) =>
      _saveFiche(
        (chapitre) => chapitre.copyWith(blocs: blocs),
        announce: announce ? ChapitreFeedbackKind.contentSaved : null,
      );

  Future<void> addNote(String texte) async {
    final chapitre = state.detail?.chapitre;
    if (chapitre == null || texte.trim().isEmpty) return;
    final result = await _addNote(chapitre, texte);
    if (isClosed) return;
    _feedback(
      result.isRight()
          ? ChapitreFeedbackKind.noteAdded
          : ChapitreFeedbackKind.writeFailed,
    );
    await refresh();
  }

  /// Masque la note et arme sa suppression ; [undoNoteDeletion] la rend.
  void requestNoteDeletion(String noteId) {
    if (_pendingDeletions.containsKey(noteId)) return;
    _pendingDeletions[noteId] = Timer(
      undoWindow,
      () => unawaited(_commitNoteDeletion(noteId)),
    );
    emit(
      state.copyWith(
        hiddenNotes: {...state.hiddenNotes, noteId},
        feedback: ChapitreFeedback(
          ChapitreFeedbackKind.noteDeleted,
          ++_seq,
          noteId: noteId,
        ),
      ),
    );
  }

  void undoNoteDeletion(String noteId) {
    _pendingDeletions.remove(noteId)?.cancel();
    if (isClosed) return;
    emit(state.copyWith(hiddenNotes: {...state.hiddenNotes}..remove(noteId)));
  }

  Future<Either<Failure, Uint8List>> openDocument(
    ChapitreRessource ressource,
  ) => _openDocument(ressource);

  Future<void> _commitNoteDeletion(String noteId) async {
    if (_pendingDeletions.remove(noteId) == null) return;
    final result = await _deleteNote(noteId);
    if (isClosed) return;
    if (result.isLeft()) _feedback(ChapitreFeedbackKind.writeFailed);
    await refresh();
    if (!isClosed) {
      emit(state.copyWith(hiddenNotes: {...state.hiddenNotes}..remove(noteId)));
    }
  }

  Future<bool> _saveFiche(
    Chapitre Function(Chapitre chapitre) change, {
    ChapitreFeedbackKind? announce,
  }) async {
    final detail = state.detail;
    if (detail == null || detail.chapitre.awaitingDownload) return false;
    final changed = change(detail.chapitre);
    emit(
      state.copyWith(
        detail: ChapitreDetail(
          chapitre: changed,
          numero: detail.numero,
          evaluations: detail.evaluations,
        ),
      ),
    );
    final result = await _save(changed);
    if (isClosed) return result.isRight();
    if (result.isLeft()) {
      _feedback(ChapitreFeedbackKind.writeFailed);
    } else if (announce != null) {
      _feedback(announce);
    }
    await refresh();
    return result.isRight();
  }

  void _feedback(ChapitreFeedbackKind kind) =>
      emit(state.copyWith(feedback: ChapitreFeedback(kind, ++_seq)));

  @override
  Future<void> close() async {
    _unwatch?.call();
    final pending = [..._pendingDeletions.keys];
    for (final timer in _pendingDeletions.values) {
      timer.cancel();
    }
    _pendingDeletions.clear();
    await super.close();
    // Quitter l'écran n'annule pas une suppression demandée.
    for (final noteId in pending) {
      await _deleteNote(noteId);
    }
  }
}
