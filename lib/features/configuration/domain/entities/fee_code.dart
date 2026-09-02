import 'package:equatable/equatable.dart';

/// Une **section** de la grille : la nature de frais telle que *cette* école la
/// nomme (`GET /finance/fee-codes`).
///
/// **Servi, jamais figé côté client** (D-5 du plan). Le serveur en connaît une
/// vingtaine et peut en ajouter sans release de l'application ; une constante
/// Dart aurait supprimé cette propriété, qui est la seule raison de consommer
/// une route plutôt qu'un fichier.
///
/// Depuis V115 la route n'est plus un référentiel figé identique pour tous : le
/// titre, l'ordre et la visibilité appartiennent à l'établissement. Seul [code]
/// reste une clé, identique d'une école à l'autre — c'est lui qui part sur le
/// fil, jamais le titre.
class FeeCodeOption extends Equatable {
  /// Valeur sur le fil (`TUITION`). Un code inconnu du serveur rend 422.
  final String code;

  /// Le titre de section que la direction a écrit, ou la proposition française
  /// du serveur tant qu'elle ne l'a pas réécrite.
  ///
  /// Celui qui figure sur la note de perception reste le libellé **du tarif**,
  /// pas celui-ci : ici, on nomme la section qui regroupe les tarifs.
  final String label;

  /// La section est-elle encore proposée à la saisie ?
  ///
  /// Une section masquée reste comptée dans les statistiques : la masquer dit
  /// « ne me la propose plus », jamais « fais comme si elle n'avait rien
  /// encaissé ». La liste par défaut ne la sert pas — il faut la demander.
  final bool active;

  /// Rang d'affichage servi par le serveur, **déjà appliqué à l'ordre de la
  /// liste**. Conservé pour que l'écran de nommage sache ce qu'il modifie, et
  /// pour reconnaître une école qui n'a rien classé
  /// (cf. `FeeCodeOrdering.isConfigured`).
  final int sortOrder;

  const FeeCodeOption({
    required this.code,
    required this.label,
    this.active = true,
    required this.sortOrder,
  });

  FeeCodeOption copyWith({String? label, bool? active, int? sortOrder}) =>
      FeeCodeOption(
        code: code,
        label: label ?? this.label,
        active: active ?? this.active,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  @override
  List<Object?> get props => [code, label, active, sortOrder];
}

/// Ce qu'une école décide d'une section : son titre, sa visibilité, son rang.
///
/// **Chaque champ est indépendamment facultatif**, seul [code] est requis :
/// masquer une section s'écrit sans réémettre son titre, et un champ laissé nul
/// laisse la valeur en place — il ne la remet pas au défaut.
class FeeCodeSectionEdit extends Equatable {
  final String code;
  final String? label;
  final bool? active;
  final int? sortOrder;

  const FeeCodeSectionEdit({
    required this.code,
    this.label,
    this.active,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [code, label, active, sortOrder];
}
