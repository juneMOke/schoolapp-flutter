/// Les champs que le serveur remplace pour chaque couple (tuteur, élève), au
/// moment de l'envoi. Toute autre accolade est refusée
/// (`ANNOUNCEMENT_UNKNOWN_VARIABLE`).
enum AnnouncementVariable {
  /// « Prénom NOM » de l'élève.
  student('{eleve}'),

  /// Sa classe, sinon le libellé de son niveau.
  classroom('{classe}'),

  /// Le reste dû, par devise, jamais converti. Réservé au mode Retards de
  /// paiement (`ANNOUNCEMENT_AMOUNT_OUTSIDE_OVERDUE`).
  amount('{montant}');

  const AnnouncementVariable(this.token);

  /// Le jeton tel qu'il s'écrit dans le message.
  final String token;

  static AnnouncementVariable? ofToken(String token) {
    for (final value in values) {
      if (value.token == token) return value;
    }
    return null;
  }
}

/// Une insertion : le texte obtenu et la place du curseur après le jeton.
typedef VariableInsertion = ({String text, int cursor});

/// Lecture et écriture des variables d'un texte, sans état.
abstract final class AnnouncementVariables {
  static final RegExp _braces = RegExp(r'\{[^{}]*\}');

  /// Les variables connues présentes dans [text], dans l'ordre de l'énumération.
  static Set<AnnouncementVariable> usedIn(String text) {
    final found = <AnnouncementVariable>{};
    for (final match in _braces.allMatches(text)) {
      final variable = AnnouncementVariable.ofToken(match.group(0)!);
      if (variable != null) found.add(variable);
    }
    return {
      for (final value in AnnouncementVariable.values)
        if (found.contains(value)) value,
    };
  }

  /// Les accolades que le serveur refuserait (`{date}`, `{}`…), sans doublon.
  ///
  /// Les repères entre crochets que les modèles suggèrent (« [date] ») ne sont
  /// pas des variables : ils passent tels quels.
  static List<String> unknownIn(String text) => [
    ...{
      for (final match in _braces.allMatches(text))
        if (AnnouncementVariable.ofToken(match.group(0)!) == null)
          match.group(0)!,
    },
  ];

  /// Insère [variable] à la place de la sélection [start]–[end] de [text].
  ///
  /// Une sélection invalide (champ jamais touché : -1) insère en fin de texte.
  static VariableInsertion insert(
    String text,
    AnnouncementVariable variable, {
    required int start,
    required int end,
  }) {
    final valid = start >= 0 && end >= start && end <= text.length;
    final from = valid ? start : text.length;
    final to = valid ? end : text.length;
    final next = text.replaceRange(from, to, variable.token);
    return (text: next, cursor: from + variable.token.length);
  }

  /// Remplace chaque variable connue par sa valeur dans [values] ; une
  /// variable sans valeur reste écrite telle quelle.
  static String render(String text, Map<AnnouncementVariable, String> values) =>
      text.replaceAllMapped(_braces, (match) {
        final token = match.group(0)!;
        final variable = AnnouncementVariable.ofToken(token);
        return variable == null ? token : values[variable] ?? token;
      });
}
