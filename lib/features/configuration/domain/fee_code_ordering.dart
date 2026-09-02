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
  /// **Un repli, plus une décision.** Depuis V115 le serveur sert le rang que
  /// l'école a choisi ; cette liste ne sert donc plus que devant un
  /// établissement qui n'a rien classé — et devant un serveur antérieur, qui ne
  /// sert aucun rang. Dès que l'école a parlé, [isConfigured] le voit et cette
  /// constante ne s'applique plus.
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

  /// L'école a-t-elle nommé, classé ou masqué ses sections ?
  ///
  /// Se lit dans ce que le serveur sert, sans champ supplémentaire : une école
  /// qui n'a rien paramétré reçoit les rangs `0, 1, … n-1`, dans cet ordre et
  /// sans trou. Un rang qui ne vaut pas sa position signifie donc qu'une
  /// décision a été prise — une section hissée en tête, ou une autre masquée qui
  /// laisse un trou dans la suite.
  ///
  /// C'est ce qui permet de ne pas imposer l'ordre du serveur à une école qui ne
  /// l'a pas choisi : les vingt-trois natures de l'énumération, servies à plat,
  /// noieraient les trois qu'un directeur saisit réellement.
  static bool isConfigured(List<FeeCodeOption> served) {
    for (var index = 0; index < served.length; index++) {
      if (served[index].sortOrder != index) return true;
    }
    return false;
  }

  /// Les sections à montrer d'emblée.
  ///
  /// **L'ordre de l'école prime** : dès qu'elle a classé ou masqué quoi que ce
  /// soit, tout est montré dans l'ordre servi et le dépliant disparaît — reléguer
  /// derrière « Autres types » une section qu'elle vient de hisser en tête serait
  /// défaire sous ses yeux ce qu'elle vient de décider.
  static List<FeeCodeOption> common(List<FeeCodeOption> served) {
    if (isConfigured(served)) return served;
    final byCode = {for (final option in served) option.code: option};
    return [
      for (final code in preferred)
        if (byCode.containsKey(code)) byCode[code]!,
    ];
  }

  /// Tout le reste, dans l'ordre du serveur — vide dès que l'école a classé.
  ///
  /// Le dépliant « Autres types » : un directeur qui facture un laboratoire ou
  /// une bibliothèque n'a aucune raison de se le voir refuser par l'écran.
  static List<FeeCodeOption> others(List<FeeCodeOption> served) {
    if (isConfigured(served)) return const <FeeCodeOption>[];
    return [
      for (final option in served)
        if (!preferred.contains(option.code)) option,
    ];
  }
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
