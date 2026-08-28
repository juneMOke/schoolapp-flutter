import 'package:equatable/equatable.dart';

/// Un type de frais du catalogue serveur (`GET /finance/fee-codes`).
///
/// **Servi, jamais figé côté client** (D-5 du plan). Le serveur en connaît une
/// vingtaine et peut en ajouter sans release de l'application ; une constante
/// Dart aurait supprimé cette propriété, qui est la seule raison de consommer
/// une route plutôt qu'un fichier.
class FeeCodeOption extends Equatable {
  /// Valeur sur le fil (`TUITION`). Un code inconnu du serveur rend 422.
  final String code;

  /// Libellé servi. Celui qui figure sur la note de perception est le libellé
  /// **saisi par le promoteur**, pas celui-ci : ici, on nomme le type.
  final String label;

  const FeeCodeOption({required this.code, required this.label});

  @override
  List<Object?> get props => [code, label];
}
