import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';

sealed class PayerSearchState extends Equatable {
  const PayerSearchState();

  @override
  List<Object?> get props => [];
}

/// Aucune suggestion, aucune recherche : l'élève n'a pas d'historique et aucun
/// tuteur connu. La popin invite alors à chercher.
class PayerSearchInitial extends PayerSearchState {
  const PayerSearchInitial();
}

class PayerSearchLoading extends PayerSearchState {
  const PayerSearchLoading();
}

/// Résultats affichés. [isSuggestion] distingue « proposé d'office à
/// l'ouverture » de « trouvé par une recherche » : ce ne sont pas les mêmes
/// listes, et l'état vide qui les suit ne dit pas la même chose non plus
/// (« personne n'a encore payé pour cet élève » ≠ « aucun payeur ne correspond
/// à ces critères »).
class PayerSearchLoaded extends PayerSearchState {
  final List<LocalPayerIdentity> results;
  final bool isSuggestion;

  const PayerSearchLoaded(this.results, {this.isSuggestion = false});

  @override
  List<Object?> get props => [results, isSuggestion];
}

/// Recherche exécutée, aucun payeur ne correspond.
class PayerSearchEmpty extends PayerSearchState {
  const PayerSearchEmpty();
}

class PayerSearchError extends PayerSearchState {
  final String message;

  const PayerSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
