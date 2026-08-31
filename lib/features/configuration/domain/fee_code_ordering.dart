import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';

/// Mise en ordre du catalogue de frais servi.
///
/// **C'est un ordre, jamais un filtre.** Le serveur connaît une vingtaine de
/// types et peut en ajouter sans release de l'application ; le front n'en cache
/// aucun. Ce qui est décidé ici, c'est seulement lesquels sont en tête — les
/// trois qu'un directeur saisit réellement ne doivent pas se noyer parmi vingt.
///
/// Deux conséquences à tenir :
/// - un code servi que cette liste ne nomme pas tombe dans « autres », **jamais
///   dans l'oubli** ;
/// - un code nommé ici que le serveur ne sert plus disparaît sans erreur : on
///   n'affiche que l'intersection.
///
/// C'est ce qui distingue ce tri d'une constante de référentiel : rien ici n'est
/// une source, et supprimer ce fichier ne retirerait aucun type à l'écran.
class FeeCodeOrdering {
  const FeeCodeOrdering._();

  /// Les types du quotidien d'une école, dans l'ordre où on les saisit.
  ///
  /// Idéalement servi par le serveur (`displayOrder`) : le jour où il l'est,
  /// cette liste disparaît sans que rien d'autre ne bouge.
  static const List<String> preferred = [
    'REGISTRATION',
    'TUITION',
    'CANTEEN',
    'TRANSPORT',
    'INSURANCE',
    'UNIFORM',
    'BOOKS',
    'EXAMINATION',
  ];

  /// Les types usuels effectivement servis, dans l'ordre de [preferred].
  static List<FeeCodeOption> common(List<FeeCodeOption> served) {
    final byCode = {for (final option in served) option.code: option};
    return [
      for (final code in preferred)
        if (byCode.containsKey(code)) byCode[code]!,
    ];
  }

  /// Tout le reste, dans l'ordre du serveur.
  ///
  /// Le dépliant « Autres types » : un directeur qui facture un laboratoire ou
  /// une bibliothèque n'a aucune raison de se le voir refuser par l'écran.
  static List<FeeCodeOption> others(List<FeeCodeOption> served) => [
    for (final option in served)
      if (!preferred.contains(option.code)) option,
  ];
}

/// Montants indicatifs, en centimes, pour les types les plus courants.
///
/// **Une aide à la saisie, pas une donnée.** Ils ne pré-remplissent que si le
/// champ est vide, et un type qui n'en a pas ouvre simplement sur un montant
/// vierge — ce qui est le cas des quinze autres.
///
/// À reverser au serveur s'il vient à les porter.
const Map<String, int> kIndicativeAmountsInCents = {
  'REGISTRATION': 7500,
  'TUITION': 68000,
  'CANTEEN': 8000,
  'TRANSPORT': 12000,
  'INSURANCE': 2500,
  'UNIFORM': 5500,
  'BOOKS': 9500,
  'EXAMINATION': 4000,
};
