import 'package:equatable/equatable.dart';

sealed class ParentSearchEvent extends Equatable {
  const ParentSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Recherche locale d'un tuteur existant (popin "Rechercher un parent") — au
/// moins un critère non vide requis, sinon la recherche n'est pas déclenchée.
class ParentSearchRequested extends ParentSearchEvent {
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? phoneNumber;

  const ParentSearchRequested({
    this.firstName,
    this.lastName,
    this.surname,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [firstName, lastName, surname, phoneNumber];
}
