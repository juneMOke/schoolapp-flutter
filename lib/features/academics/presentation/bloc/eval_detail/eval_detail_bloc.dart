import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';

/// Page de pilotage d'une évaluation (spec S1) : son sujet et l'avancement de
/// la saisie, lus en local.
class EvalDetailBloc extends Bloc<EvalDetailEvent, EvalDetailState> {
  final GetEvaluationSujetUseCase _getSujet;
  final GetNotesElevesUseCase _getNotes;

  EvalDetailBloc({
    required GetEvaluationSujetUseCase getEvaluationSujetUseCase,
    required GetNotesElevesUseCase getNotesElevesUseCase,
  }) : _getSujet = getEvaluationSujetUseCase,
       _getNotes = getNotesElevesUseCase,
       super(const EvalDetailState()) {
    on<EvalDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    EvalDetailRequested event,
    Emitter<EvalDetailState> emit,
  ) async {
    if (state.status == EvalDetailStatus.failure) {
      emit(state.copyWith(status: EvalDetailStatus.loading));
    }
    final (sujet, notes) = await (
      _getSujet(event.evaluationId),
      _getNotes(event.evaluationId),
    ).wait;
    final loaded = sujet.flatMap(
      (s) => notes.map<(EvaluationSujet, NotesProgress)>(
        (n) => (s, _progressOf(n)),
      ),
    );
    loaded.fold(
      (failure) => emit(
        state.copyWith(
          status: EvalDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: EvalDetailStatus.ready,
          sujet: data.$1,
          progress: data.$2,
          failure: () => null,
        ),
      ),
    );
  }

  static NotesProgress _progressOf(List<NoteEleve> notes) => NotesProgress(
    saisies: notes
        .where((n) => n.statut != null && n.statut != StatutNote.enAttente)
        .length,
    total: notes.length,
  );
}
