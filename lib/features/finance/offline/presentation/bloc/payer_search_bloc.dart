import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_state.dart';

/// BLoC de la popin « Choisir un payeur » — lecture 100% locale, aucun appel
/// réseau, scope transitoire (créé et fermé avec la popin, `registerFactory`).
class PayerSearchBloc extends Bloc<PayerSearchEvent, PayerSearchState> {
  final GetPayerSuggestionsUseCase _suggestions;
  final SearchPayersUseCase _search;

  /// Le transformer par défaut du bloc étant `concurrent`, une recherche plus
  /// récente doit gagner sur une recherche périmée résolue en dernier. Le
  /// compteur est PARTAGÉ entre suggestions et recherche : les suggestions
  /// partent à l'ouverture, et une recherche lancée pendant qu'elles courent
  /// encore doit les périmer — sinon la liste des propositions écraserait le
  /// résultat que le guichetier vient de demander.
  int _generation = 0;

  PayerSearchBloc({
    required GetPayerSuggestionsUseCase suggestions,
    required SearchPayersUseCase search,
  }) : _suggestions = suggestions,
       _search = search,
       super(const PayerSearchInitial()) {
    on<PayerSuggestionsRequested>(_onSuggestions);
    on<PayerSearchRequested>(_onSearch);
  }

  Future<void> _onSuggestions(
    PayerSuggestionsRequested event,
    Emitter<PayerSearchState> emit,
  ) async {
    final generation = ++_generation;
    emit(const PayerSearchLoading());
    final result = await _suggestions(event.studentId);
    if (generation != _generation) return; // résultat périmé, ignoré

    emit(
      result.fold(
        (f) => PayerSearchError(_map(f)),
        // Aucune suggestion ne vaut PAS « aucun résultat » : rien n'a été
        // cherché. On retombe sur l'état initial, qui invite à chercher, plutôt
        // que sur un vide qui laisserait croire à une recherche infructueuse.
        (payers) => payers.isEmpty
            ? const PayerSearchInitial()
            : PayerSearchLoaded(payers, isSuggestion: true),
      ),
    );
  }

  Future<void> _onSearch(
    PayerSearchRequested event,
    Emitter<PayerSearchState> emit,
  ) async {
    final generation = ++_generation;
    emit(const PayerSearchLoading());
    final result = await _search(
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      phoneNumber: event.phoneNumber,
    );
    if (generation != _generation) return; // résultat périmé, ignoré

    emit(
      result.fold(
        (f) => PayerSearchError(_map(f)),
        (payers) => payers.isEmpty
            ? const PayerSearchEmpty()
            : PayerSearchLoaded(payers),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
