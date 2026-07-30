import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_state.dart';

/// BLoC dédié à la popin "Rechercher un parent" (étape Tuteurs) — recherche
/// locale 100% (aucun appel réseau), scope transitoire (créé/fermé avec la
/// popin, `registerFactory`).
class ParentSearchBloc extends Bloc<ParentSearchEvent, ParentSearchState> {
  final SearchParentsUseCase _search;

  // Le transformer par défaut du bloc étant `concurrent`, une recherche plus
  // récente doit gagner sur une recherche périmée résolue en dernier (même
  // patron que `EnrollmentLocalListBloc`).
  int _generation = 0;

  ParentSearchBloc({required SearchParentsUseCase search})
    : _search = search,
      super(const ParentSearchInitial()) {
    on<ParentSearchRequested>(_onSearch);
  }

  Future<void> _onSearch(
    ParentSearchRequested event,
    Emitter<ParentSearchState> emit,
  ) async {
    final generation = ++_generation;
    emit(const ParentSearchLoading());
    final result = await _search(
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      phoneNumber: event.phoneNumber,
    );
    if (generation != _generation) return; // résultat périmé, ignoré

    emit(
      result.fold(
        (f) => ParentSearchError(_map(f)),
        (parents) => parents.isEmpty
            ? const ParentSearchEmpty()
            : ParentSearchLoaded(parents),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
