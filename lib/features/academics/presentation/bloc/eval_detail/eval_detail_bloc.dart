import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/resend_sujet_without_max_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/save_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';

/// Page de pilotage d'une évaluation (spec S1) : son sujet et l'avancement de
/// la saisie, lus en local ; l'enregistrement du sujet (S4).
class EvalDetailBloc extends Bloc<EvalDetailEvent, EvalDetailState> {
  final GetEvaluationSujetUseCase _getSujet;
  final GetNotesElevesUseCase _getNotes;
  final SaveEvaluationSujetUseCase _saveSujet;
  final ResendSujetWithoutMaxUseCase _resendSujet;

  EvalDetailBloc({
    required GetEvaluationSujetUseCase getEvaluationSujetUseCase,
    required GetNotesElevesUseCase getNotesElevesUseCase,
    required SaveEvaluationSujetUseCase saveEvaluationSujetUseCase,
    required ResendSujetWithoutMaxUseCase resendSujetWithoutMaxUseCase,
  }) : _getSujet = getEvaluationSujetUseCase,
       _getNotes = getNotesElevesUseCase,
       _saveSujet = saveEvaluationSujetUseCase,
       _resendSujet = resendSujetWithoutMaxUseCase,
       super(const EvalDetailState()) {
    on<EvalDetailRequested>(_onRequested);
    on<EvalDetailSujetSaveRequested>(_onSujetSave);
    on<EvalDetailSujetResendRequested>(_onSujetResend);
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

  Future<void> _onSujetSave(
    EvalDetailSujetSaveRequested event,
    Emitter<EvalDetailState> emit,
  ) async {
    if (state.sujetSave == SujetSaveStatus.saving) return;
    // Garde du maximum figé : une note posée le borne (refus serveur
    // `MAX_LOCKED`) — on ne l'envoie pas.
    final maxPoints = state.progress.maxLocked ? null : event.maxPoints;
    emit(state.copyWith(sujetSave: SujetSaveStatus.saving));
    final result = await _saveSujet(
      event.evaluationId,
      cadre: event.cadre,
      questions: event.questions,
      maxPoints: maxPoints,
    );
    result.fold(
      (_) => emit(state.copyWith(sujetSave: SujetSaveStatus.failed)),
      (sujet) => emit(
        state.copyWith(
          sujet: sujet,
          sujetSave: SujetSaveStatus.saved,
          maxPoints: maxPoints,
        ),
      ),
    );
    // L'issue est consommée par l'écran ; la suivante repart d'un état neutre.
    emit(state.copyWith(sujetSave: SujetSaveStatus.idle));
  }

  Future<void> _onSujetResend(
    EvalDetailSujetResendRequested event,
    Emitter<EvalDetailState> emit,
  ) async {
    // Même garde que l'enregistrement : un seul envoi du sujet à la fois.
    if (state.sujetSave == SujetSaveStatus.saving) return;
    emit(state.copyWith(sujetSave: SujetSaveStatus.saving));
    final result = await _resendSujet(event.evaluationId);
    result.fold(
      (_) => emit(state.copyWith(sujetSave: SujetSaveStatus.failed)),
      (sujet) =>
          emit(state.copyWith(sujet: sujet, sujetSave: SujetSaveStatus.resent)),
    );
    emit(state.copyWith(sujetSave: SujetSaveStatus.idle));
  }

  static NotesProgress _progressOf(List<NoteEleve> notes) => NotesProgress(
    saisies: notes
        .where((n) => n.statut != null && n.statut != StatutNote.enAttente)
        .length,
    total: notes.length,
    notees: notes.where((n) => n.statut == StatutNote.notee).length,
  );
}
