import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_use_case.dart';

part 'enrollment_entries_event.dart';
part 'enrollment_entries_state.dart';

/// La liste nominative de la fenêtre — **un second appel, subordonné au
/// premier**.
///
/// ## Pourquoi un BLoC à part
///
/// 1. **Une seconde permission.** Le serveur exige `enrollment.read` en plus
///    de `enrollment.stats.read`. Un utilisateur qui n'a que le pilotage reçoit
///    200 sur l'agrégat et **403 ici**. Deux réponses différentes ne peuvent
///    pas vivre dans un état commun.
/// 2. **Une pagination**, qui n'a aucun sens pour l'agrégat.
///
/// ## Ce que ce BLoC ne décide PAS
///
/// Il ne décide ni **quand** charger, ni **quelle fenêtre**. C'est le bloc de
/// l'agrégat qui fait autorité : un écouteur du scope lui transmet la fenêtre
/// dès que les chiffres sont arrivés, et le vide sinon.
///
/// ## Une réponse en retard ne s'affiche jamais
///
/// Deux lectures peuvent se croiser : une page demandée juste avant un
/// changement de fenêtre peut revenir **après** la première page de la
/// nouvelle. Sur une journée la course était rare ; sur une année entière la
/// requête dure assez pour la rendre ordinaire. Chaque réponse est donc
/// confrontée à la demande en cours — fenêtre ET page — et jetée si elle n'y
/// correspond plus : des noms de septembre sous le titre « cette semaine »
/// seraient pires qu'une table en chargement.
class EnrollmentEntriesBloc
    extends Bloc<EnrollmentEntriesEvent, EnrollmentEntriesState> {
  final GetEnrollmentEntriesUseCase _getEntriesUseCase;

  EnrollmentEntriesBloc({
    required GetEnrollmentEntriesUseCase getEntriesUseCase,
  }) : _getEntriesUseCase = getEntriesUseCase,
       super(const EnrollmentEntriesState()) {
    on<EnrollmentEntriesRequested>(_onRequested);
    on<EnrollmentEntriesPageChanged>(_onPageChanged);
    on<EnrollmentEntriesCleared>(_onCleared);
  }

  Future<void> _onRequested(
    EnrollmentEntriesRequested event,
    Emitter<EnrollmentEntriesState> emit,
  ) async {
    // Changer de fenêtre **remet la pagination à zéro**. Rester page 3 en
    // passant de l'année à la semaine afficherait une page vide d'une liste
    // qui, elle, a des lignes.
    await _load(emit, window: event.window, page: 0);
  }

  Future<void> _onPageChanged(
    EnrollmentEntriesPageChanged event,
    Emitter<EnrollmentEntriesState> emit,
  ) async {
    final window = state.window;
    if (window == null) return;
    // La barre désarme déjà ses boutons aux extrémités ; une page hors bornes
    // ne peut venir que d'un appel direct, et une page négative partirait en
    // 400.
    if (event.page < 0 || event.page >= state.totalPages) return;
    await _load(emit, window: window, page: event.page);
  }

  void _onCleared(
    EnrollmentEntriesCleared event,
    Emitter<EnrollmentEntriesState> emit,
  ) {
    emit(const EnrollmentEntriesState());
  }

  Future<void> _load(
    Emitter<EnrollmentEntriesState> emit, {
    required EnrollmentStatsWindow window,
    required int page,
  }) async {
    emit(
      state.copyWith(
        status: EnrollmentEntriesStatus.loading,
        window: window,
        page: page,
        failure: null,
      ),
    );

    final result = await _getEntriesUseCase(window: window, page: page);

    // Réponse périmée : une autre demande a pris la main entre-temps.
    if (state.window != window || state.page != page) return;

    result.fold(
      // Même règle que sur l'agrégat : l'échec emporte les lignes. Une page
      // de noms périmée sous un message d'erreur serait au mieux troublante,
      // au pire fausse.
      (failure) => emit(
        state.copyWith(
          status: EnrollmentEntriesStatus.error,
          entries: const [],
          failure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          status: paged.content.isEmpty
              ? EnrollmentEntriesStatus.empty
              : EnrollmentEntriesStatus.success,
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
