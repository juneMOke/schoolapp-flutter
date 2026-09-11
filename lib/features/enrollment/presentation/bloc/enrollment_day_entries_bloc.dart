import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_day_entries_use_case.dart';

part 'enrollment_day_entries_event.dart';
part 'enrollment_day_entries_state.dart';

/// La liste nominative du jour — **un second appel, subordonné au premier**.
///
/// ## Pourquoi un BLoC à part
///
/// Trois raisons, et aucune n'est de confort :
///
/// 1. **Une seconde permission.** Le serveur exige `enrollment.read` en plus
///    de `enrollment.stats.read`. Un utilisateur qui n'a que le pilotage reçoit
///    200 sur l'agrégat et **403 ici**. Deux réponses différentes ne peuvent
///    pas vivre dans un état commun.
/// 2. **Une pagination**, qui n'a aucun sens pour l'agrégat.
/// 3. **Une condition d'existence** : la carte n'a lieu d'être que sur une
///    fenêtre d'un seul jour.
///
/// ## Ce que ce BLoC ne décide PAS
///
/// Il ne décide ni **quand** charger, ni **quel jour**. C'est le bloc de
/// l'agrégat qui fait autorité : la page ne construit ce sous-arbre que dans
/// sa branche `success`, et un écouteur lui transmet la journée. Si l'agrégat
/// échoue, ce BLoC n'est pas dans l'arbre du tout — la règle « l'erreur
/// remplace tout le contenu » est ainsi tenue par la structure, pas par une
/// condition qu'un widget pourrait oublier.
class EnrollmentDayEntriesBloc
    extends Bloc<EnrollmentDayEntriesEvent, EnrollmentDayEntriesState> {
  final GetEnrollmentDayEntriesUseCase _getDayEntriesUseCase;

  EnrollmentDayEntriesBloc({
    required GetEnrollmentDayEntriesUseCase getDayEntriesUseCase,
  }) : _getDayEntriesUseCase = getDayEntriesUseCase,
       super(const EnrollmentDayEntriesState()) {
    on<EnrollmentDayEntriesRequested>(_onRequested);
    on<EnrollmentDayEntriesPageChanged>(_onPageChanged);
    on<EnrollmentDayEntriesCleared>(_onCleared);
  }

  Future<void> _onRequested(
    EnrollmentDayEntriesRequested event,
    Emitter<EnrollmentDayEntriesState> emit,
  ) async {
    // Changer de jour **remet la pagination à zéro**. Rester page 3 en
    // changeant de journée afficherait une page vide d'une liste qui, elle,
    // a des lignes.
    await _load(emit, day: event.day, page: 0);
  }

  Future<void> _onPageChanged(
    EnrollmentDayEntriesPageChanged event,
    Emitter<EnrollmentDayEntriesState> emit,
  ) async {
    final day = state.day;
    if (day == null) return;
    await _load(emit, day: day, page: event.page);
  }

  void _onCleared(
    EnrollmentDayEntriesCleared event,
    Emitter<EnrollmentDayEntriesState> emit,
  ) {
    emit(const EnrollmentDayEntriesState());
  }

  Future<void> _load(
    Emitter<EnrollmentDayEntriesState> emit, {
    required DateTime day,
    required int page,
  }) async {
    emit(
      state.copyWith(
        status: EnrollmentDayEntriesStatus.loading,
        day: day,
        page: page,
        failure: null,
      ),
    );

    final result = await _getDayEntriesUseCase(day: day, page: page);

    result.fold(
      // Même règle que sur l'agrégat : l'échec emporte les lignes. Une page
      // de noms périmée sous un message d'erreur serait au mieux troublante,
      // au pire fausse.
      (failure) => emit(
        state.copyWith(
          status: EnrollmentDayEntriesStatus.error,
          entries: const [],
          failure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          status: paged.content.isEmpty
              ? EnrollmentDayEntriesStatus.empty
              : EnrollmentDayEntriesStatus.success,
          entries: paged.content,
          totalElements: paged.totalElements,
          totalPages: paged.totalPages,
          // ⚠️ **La page affichée est celle DEMANDÉE**, jamais l'écho que la
          // réponse en fait. C'est cet écho qui bloquait la pagination : lu
          // sous un nom de champ que le serveur n'envoie pas, il valait
          // toujours 0, si bien que « suivant » redemandait sans fin la
          // page 1 et que l'indicateur restait sur « 1 / N ».
          page: page,
          failure: null,
        ),
      ),
    );
  }
}
