import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

sealed class ParentSearchState extends Equatable {
  const ParentSearchState();

  @override
  List<Object?> get props => [];
}

/// Aucune recherche lancée (popin fraîchement ouverte).
class ParentSearchInitial extends ParentSearchState {
  const ParentSearchInitial();
}

class ParentSearchLoading extends ParentSearchState {
  const ParentSearchLoading();
}

class ParentSearchLoaded extends ParentSearchState {
  final List<LocalParent> results;

  const ParentSearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

/// Recherche exécutée, aucun résultat.
class ParentSearchEmpty extends ParentSearchState {
  const ParentSearchEmpty();
}

class ParentSearchError extends ParentSearchState {
  final String message;

  const ParentSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
