import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_edit_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_change_source.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';

/// Le programme d'un cours : lecture locale, relue en silence à chaque signal
/// ([ProgrammeChangeSource]), et les gestes du programme — créer ou modifier
/// un chapitre, réordonner, supprimer.
///
/// Réordonner est **optimiste** : la liste bouge tout de suite, la relecture
/// suit ; un échec d'écriture locale remet l'ordre lu et le dit.
class ProgrammeCubit extends Cubit<ProgrammeState> {
  final String coursId;
  final LoadProgrammeUseCase _load;
  final LoadChapitreUseCase _loadChapitre;
  final LoadSousPeriodesUseCase _loadSousPeriodes;
  final SaveChapitreEditUseCase _saveEdit;
  final ReorderChapitresUseCase _reorder;
  final DeleteChapitreUseCase _delete;
  final ProgrammeChangeSource _source;

  /// Un identifiant neuf (chapitre, objectif, ressource).
  final String Function() newId;
  void Function()? _unwatch;
  var _seq = 0;

  ProgrammeCubit({
    required this.coursId,
    required LoadProgrammeUseCase load,
    required LoadChapitreUseCase loadChapitre,
    required LoadSousPeriodesUseCase loadSousPeriodes,
    required SaveChapitreEditUseCase saveEdit,
    required ReorderChapitresUseCase reorder,
    required DeleteChapitreUseCase delete,
    required ProgrammeChangeSource source,
    required this.newId,
  }) : _load = load,
       _loadChapitre = loadChapitre,
       _loadSousPeriodes = loadSousPeriodes,
       _saveEdit = saveEdit,
       _reorder = reorder,
       _delete = delete,
       _source = source,
       super(const ProgrammeState());

  Future<void> load() async {
    emit(const ProgrammeState());
    await refresh();
    if (isClosed) return;
    // Lu en ligne, rien que l'outbox puisse changer : les flush n'ont pas à
    // le relire (une requête réseau chacun).
    _unwatch ??= _source.watch(
      () => unawaited(refresh()),
      onFlush: !(state.programme?.readOnly ?? false),
    );
    final sousPeriodes = await _loadSousPeriodes(coursId);
    if (!isClosed) emit(state.copyWith(sousPeriodes: sousPeriodes));
  }

  /// Relecture : un échec ne remplace jamais une liste déjà affichée.
  Future<void> refresh() async {
    final result = await _load(coursId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (state.programme == null) {
          emit(
            state.copyWith(status: ProgrammeStatus.failure, failure: failure),
          );
        }
      },
      (programme) => emit(
        ProgrammeState(
          status: ProgrammeStatus.ready,
          programme: programme,
          feedback: state.feedback,
          sousPeriodes: state.sousPeriodes,
        ),
      ),
    );
  }

  /// Échange le chapitre [chapitreId] avec son voisin ([offset] = -1 ou 1).
  Future<void> move(String chapitreId, int offset) async {
    final programme = state.programme;
    if (programme == null || programme.readOnly) return;
    final rows = [...programme.chapitres];
    final from = rows.indexWhere((row) => row.chapitre.id == chapitreId);
    final to = from + offset;
    if (from < 0 || to < 0 || to >= rows.length) return;
    rows.insert(to, rows.removeAt(from));
    emit(
      state.copyWith(
        programme: Programme(
          coursId: programme.coursId,
          chapitres: rows,
          evaluationsCount: programme.evaluationsCount,
        ),
      ),
    );
    final result = await _reorder(coursId, [
      for (final row in rows) row.chapitre.id,
    ]);
    if (isClosed) return;
    result.fold((_) => _feedback(ProgrammeFeedbackKind.writeFailed), (_) {});
    await refresh();
  }

  /// Le chapitre entier (notes et ressources chargées), pour l'éditer.
  Future<Chapitre?> chapitreForEdit(String chapitreId) async {
    final result = await _loadChapitre(chapitreId);
    return result.fold((_) => null, (detail) => detail.chapitre);
  }

  /// Enregistre une édition venue de la modale. La fiche gardée, une
  /// ressource qui ne l'a pas été est signalée sans défaire la fiche.
  Future<void> saveEdit(ChapitreEdit edit) async {
    final result = await _saveEdit(edit);
    if (isClosed) return;
    result.fold((_) => _feedback(ProgrammeFeedbackKind.writeFailed), (outcome) {
      _feedback(
        !outcome.ressourcesKept
            ? ProgrammeFeedbackKind.ressourceKeepFailed
            : edit.isNew
            ? ProgrammeFeedbackKind.chapitreCreated
            : ProgrammeFeedbackKind.chapitreUpdated,
        titre: outcome.chapitre.titre,
      );
    });
    await refresh();
  }

  Future<void> delete(String chapitreId) async {
    if (state.programme?.readOnly ?? true) return;
    final result = await _delete(chapitreId);
    if (isClosed) return;
    _feedback(
      result.isRight()
          ? ProgrammeFeedbackKind.chapitreDeleted
          : ProgrammeFeedbackKind.writeFailed,
    );
    await refresh();
  }

  void _feedback(ProgrammeFeedbackKind kind, {String? titre}) => emit(
    state.copyWith(feedback: ProgrammeFeedback(kind, ++_seq, titre: titre)),
  );

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
