import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';

/// Met le reçu provisoire en **lignes de caractères**.
///
/// C'est le point de jonction des deux sorties de RG-012-10, reformulé : « un
/// modèle, deux renderers ». Aucune abstraction ne joint un arbre de widgets PDF
/// à un flux d'octets ESC/POS — mais les deux savent poser des lignes de texte
/// en police fixe. Ce gabarit est donc le seul endroit où la mise en page est
/// décidée, et le seul niveau réellement testable du dépôt (aucun golden test
/// n'y existe, et le rendu PDF n'est pas montable en test de widget).
///
/// Le critère d'acceptation de l'ADR — « ticket ESC/POS **et** PDF depuis le
/// même gabarit, comparaison du contenu textuel » — se vérifie exactement ici.
abstract final class TicketTextLayout {
  /// Largeur d'un ticket 80 mm en police A (12×24) sur une imprimante
  /// thermique standard. 58 mm donnerait 32, la police B 64.
  static const int defaultColumns = 48;

  static const String _separator = '-';

  /// Rend le ticket. [columns] est le nombre de caractères par ligne.
  static List<String> render(
    TicketReceiptModel model, {
    int columns = defaultColumns,
  }) {
    final width = columns < 24 ? 24 : columns;
    final lines = <String>[];

    // ── Z1 — l'établissement. Deux lignes, pas de logo, pas de mention
    // d'agrément : ce n'est pas une pièce officielle.
    lines.addAll(_centered(model.schoolName.toUpperCase(), width));
    final municipality = model.schoolMunicipality?.trim();
    if (municipality != null && municipality.isNotEmpty) {
      lines.addAll(_centered(municipality, width));
    }
    lines.add(_rule(width));

    // ── Z4 — le bandeau. Placé HAUT et pleine largeur : la dissemblance doit
    // se lire avant le contenu, y compris par quelqu'un qui lit peu le français.
    lines.add(_banner(model.labels.provisionalBanner, width));
    lines.add(_rule(width));

    // ── Z2 — l'élève.
    lines.addAll(_wrapped(model.studentFullName.toUpperCase(), width));
    _addOptional(
      lines,
      model.labels.matriculationLabel,
      model.matriculationNumber,
      width,
    );
    _addOptional(
      lines,
      model.labels.classroomLabel,
      model.classroomName,
      width,
    );
    lines.add(_rule(width));

    // ── Z3 — la traçabilité. Sur une pièce non scellée, l'imputabilité humaine
    // remplace l'imputabilité cryptographique : le caissier est obligatoire dès
    // qu'il est connu (RG-012-11).
    lines.addAll(
      _wrapped(
        '${model.labels.referenceLabel} ${model.provisionalReference}',
        width,
      ),
    );
    _addPair(
      lines,
      _formatDate(model.paidAt),
      _formatTime(model.paidAt),
      width,
    );
    _addOptional(
      lines,
      model.labels.cashierLabel,
      model.cashierFullName,
      width,
    );
    lines.add(_rule(width));

    // ── Z5 — l'argent. Montant reçu et répartition sont des FAITS : ils
    // s'impriment sans réserve (RG-012-13 — la répartition est une saisie, pas
    // un calcul). Seul le solde est incertain, et lui seul porte la mention.
    _addPair(
      lines,
      model.labels.amountReceivedLabel,
      formatAmount(model.amountReceivedInCents, model.currency),
      width,
    );

    if (model.allocations.isNotEmpty) {
      lines.add('');
      lines.add(TicketCharset.printable(model.labels.allocationsLabel));
      for (final allocation in model.allocations) {
        _addPair(
          lines,
          '  ${allocation.label}',
          formatAmount(allocation.amountInCents, model.currency),
          width,
        );
      }
    }

    final balance = model.remainingBalanceInCents;
    if (balance != null) {
      lines.add(_rule(width));
      _addPair(
        lines,
        model.labels.balanceLabel,
        formatAmount(balance, model.currency),
        width,
      );
      lines.addAll(_wrapped(model.labels.balanceReservation, width));
    }

    // Phrase de conservation (RG-012-12) : sans elle, l'établissement n'a aucun
    // levier pour rappeler un parent dont le versement poserait problème.
    lines.add(_rule(width));
    lines.addAll(_centeredWrapped(model.labels.keepTicketNotice, width));

    return lines;
  }

  /// Montant en centimes → « 1 234,56 CDF ».
  ///
  /// Formateur **pur**, sans données de locale à initialiser : le ticket doit
  /// pouvoir être rendu dans un test unitaire comme dans un isolat d'impression.
  /// Espace insécable fine exclue à dessein — une imprimante thermique ne la
  /// rend pas.
  static String formatAmount(int cents, String currency) {
    final negative = cents < 0;
    final absolute = negative ? -cents : cents;
    final units = (absolute ~/ 100).toString();
    final decimals = (absolute % 100).toString().padLeft(2, '0');

    final grouped = StringBuffer();
    for (var i = 0; i < units.length; i++) {
      if (i > 0 && (units.length - i) % 3 == 0) grouped.write(' ');
      grouped.write(units[i]);
    }

    final sign = negative ? '-' : '';
    final suffix = currency.trim().isEmpty ? '' : ' ${currency.trim()}';
    return '$sign$grouped,$decimals$suffix';
  }

  // ── Primitives de mise en page ──────────────────────────────────────────────

  static void _addOptional(
    List<String> lines,
    String label,
    String? value,
    int width,
  ) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    lines.addAll(_wrapped('$label $trimmed', width));
  }

  static String _rule(int width) => _separator * width;

  /// Bandeau pleine largeur, encadré d'espaces pour rester lisible.
  static String _banner(String rawText, int width) {
    final text = TicketCharset.printable(rawText);
    final label = ' ${text.toUpperCase()} ';
    if (label.length >= width) return label.trim();
    final total = width - label.length;
    final left = total ~/ 2;
    return '${'*' * left}$label${'*' * (total - left)}';
  }

  static List<String> _centered(String text, int width) =>
      _wrapped(text, width).map((line) => _center(line, width)).toList();

  static List<String> _centeredWrapped(String text, int width) =>
      _centered(text, width);

  static String _center(String line, int width) {
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
  static void _addPair(
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
    lines.addAll(_wrapped(label, width));
    lines.add(value.length >= width ? value : value.padLeft(width));
  }

  /// Date au format `JJ/MM/AAAA` — formateur PUR, sans données de locale à
  /// initialiser : le ticket doit se rendre dans un test unitaire comme dans un
  /// isolat d'impression.
  static String _formatDate(DateTime at) =>
      '${_two(at.day)}/${_two(at.month)}/${at.year}';

  /// Heure au format `HH:MM`.
  static String _formatTime(DateTime at) =>
      '${_two(at.hour)}:${_two(at.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Découpe sur les espaces, sans jamais couper un mot au milieu — sauf s'il
  /// dépasse à lui seul la largeur (une référence, typiquement).
  static List<String> _wrapped(String text, int width) {
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
