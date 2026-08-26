import 'package:equatable/equatable.dart';

sealed class PayerSearchEvent extends Equatable {
  const PayerSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Ouverture de la popin : on propose sans rien demander les payeurs déjà
/// connus pour cet élève. C'est le geste le plus fréquent — le même parent
/// revient — et il ne doit coûter aucune saisie.
class PayerSuggestionsRequested extends PayerSearchEvent {
  final String studentId;

  const PayerSuggestionsRequested(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

/// Recherche explicite dans l'historique des versements, toutes fiches élèves
/// confondues — au moins un critère non vide, sinon rien n'est déclenché.
class PayerSearchRequested extends PayerSearchEvent {
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? phoneNumber;

  const PayerSearchRequested({
    this.firstName,
    this.lastName,
    this.surname,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [firstName, lastName, surname, phoneNumber];
}
