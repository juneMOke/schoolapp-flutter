import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';

/// Les primitives de mise en page d'un ticket thermique : centrer, aligner,
/// découper, encadrer.
///
/// **Partagées entre les gabarits**, et c'est la raison de ce fichier. Deux
/// tickets sortent de la même imprimante — la perception et la vente boutique —
/// et deux copies de ces vingt lignes divergeraient au premier ajustement de
/// largeur, sur une colonne de montants.
///
/// Tout est **pur** : aucun `BuildContext`, aucune donnée de locale à
/// initialiser. Un ticket doit se rendre dans un test unitaire comme dans un
/// isolat d'impression.
abstract final class TicketTextPrimitives {
  /// Caractère de séparation. Jamais un trait plein : le rendu thermique en
  /// fait une bavure.
  static const String separator = '-';

  static void addOptional(
    List<String> lines,
    String label,
    String? value,
    int width,
  ) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    lines.addAll(wrapped('$label $trimmed', width));
  }

  static String rule(int width) => separator * width;

  /// Bandeau pleine largeur, encadré d'espaces pour rester lisible.
  static String banner(String rawText, int width) {
    final text = TicketCharset.printable(rawText);
    final label = ' ${text.toUpperCase()} ';
    if (label.length >= width) return label.trim();
    final total = width - label.length;
    final left = total ~/ 2;
    return '${'*' * left}$label${'*' * (total - left)}';
  }

  static List<String> centered(String text, int width) =>
      wrapped(text, width).map((line) => center(line, width)).toList();

  static List<String> centeredWrapped(String text, int width) =>
      centered(text, width);

  static String center(String line, int width) {
    if (line.length >= width) return line;
    final left = (width - line.length) ~/ 2;
    return '${' ' * left}$line';
  }

  /// `label` à gauche, `value` à droite, comblé par des espaces.
  ///
  /// Si les deux ne tiennent pas sur une ligne, la valeur passe seule sur la
  /// suivante, alignée à droite : un montant tronqué serait pire qu'un montant
  /// reporté. La méthode AJOUTE des lignes plutôt que d'en renvoyer une seule —
  /// une « ligne » porteuse d'un retour chariot casserait l'invariant de largeur
  /// sur lequel repose tout le gabarit.
  static void addPair(
    List<String> lines,
    String rawLabel,
    String rawValue,
    int width,
  ) {
    // Translittération AVANT toute mesure : `œ` → `oe` gagne un caractère, et
    // mesurer d'abord décalerait la colonne des montants.
    final label = TicketCharset.printable(rawLabel);
    final value = TicketCharset.printable(rawValue);
    final space = width - label.length - value.length;
    if (space >= 1) {
      lines.add('$label${' ' * space}$value');
      return;
    }
    lines.addAll(wrapped(label, width));
    lines.add(value.length >= width ? value : value.padLeft(width));
  }

  /// Date au format `JJ/MM/AAAA` — formateur PUR, sans données de locale à
  /// initialiser : le ticket doit se rendre dans un test unitaire comme dans un
  /// isolat d'impression.
  static String formatDate(DateTime at) =>
      '${two(at.day)}/${two(at.month)}/${at.year}';

  /// Heure au format `HH:MM`.
  static String formatTime(DateTime at) => '${two(at.hour)}:${two(at.minute)}';

  static String two(int value) => value.toString().padLeft(2, '0');

  /// Découpe sur les espaces, sans jamais couper un mot au milieu — sauf s'il
  /// dépasse à lui seul la largeur (une référence, typiquement).
  static List<String> wrapped(String text, int width) {
    final source = TicketCharset.printable(text).trim();
    if (source.isEmpty) return const <String>[];

    final lines = <String>[];
    var current = '';

    for (final word in source.split(RegExp(r'\s+'))) {
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }

      while (current.length > width) {
        lines.add(current.substring(0, width));
        current = current.substring(width);
      }
    }

    if (current.isNotEmpty) lines.add(current);
    return lines;
  }
}
