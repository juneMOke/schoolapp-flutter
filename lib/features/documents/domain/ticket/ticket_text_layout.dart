import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

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

    // Nature de la pièce, avant tout le reste : quelqu'un qui trie une liasse
    // de fin de journée doit pouvoir l'identifier sans lire le corps. Elle
    // précède le bandeau, qui la qualifie — « ticket de perception », et il est
    // provisoire.
    lines.addAll(_centered(model.labels.documentTitle.toUpperCase(), width));

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

    // Part du montant reçu qu'aucune créance n'absorbe. Elle EXISTE : un
    // versement peut dépasser le dû (`isOptimisticallyOverpaid`), le paiement
    // est alors accepté et le ticket reste valide.
    //
    // Elle s'imprime comme une ligne de répartition, et pas à part, pour une
    // raison de lecture : la ventilation somme alors exactement au montant
    // reçu. Sans elle, un parent qui additionne trouve un écart que rien
    // n'explique — le pire des trois cas, puisque le silence se lit comme une
    // erreur de caisse. Ce qu'elle ne fait PAS, c'est arbitrer le trop-perçu :
    // l'imputation définitive appartient au reçu scellé.
    // ⚠️ Uniquement quand une ventilation est IMPRIMÉE : c'est un écart visible
    // qu'on ferme, pas une comptabilité qu'on tient. Sans bloc « Répartition »,
    // le lecteur n'a aucune soustraction à faire, et une ligne d'avance seule
    // ne ferait que dupliquer le montant reçu deux lignes plus haut.
    final advance = model.amountReceivedInCents - model.allocatedInCents;
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
      // Un écart NÉGATIF (ventilation supérieure au reçu) est une saisie
      // incohérente, pas une avance : on ne l'habille pas d'un libellé qui la
      // ferait passer pour normale.
      if (advance > 0) {
        _addPair(
          lines,
          '  ${model.labels.advanceLabel}',
          formatAmount(advance, model.currency),
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

  /// Montant en centimes → « 1 234 FC », « 425,00 $ ».
  ///
  /// Façade sur [MoneyFormat], qui porte désormais la règle : les décimales se
  /// décident sur la **devise**, et `CDF` s'écrit « FC ». Le ticket écrivait
  /// jusqu'ici « 1 234,00 CDF » — deux décimales sur une devise qui n'en a pas,
  /// et le code ISO à la place de l'abréviation d'usage.
  ///
  /// Formateur **pur**, sans données de locale à initialiser : le ticket doit
  /// pouvoir être rendu dans un test unitaire comme dans un isolat d'impression.
  /// L'espace de groupement est l'**ordinaire** — une imprimante thermique ne
  /// rend pas l'insécable.
  static String formatAmount(int cents, String currency) => MoneyFormat.format(
    Money.parse(cents, currency),
    space: MoneyFormat.thermalSpace,
  );

  // ── Primitives de mise en page ──────────────────────────────────────────────
  //
  // Déléguées à `TicketTextPrimitives`, partagé avec le ticket de vente
  // boutique : deux copies divergeraient au premier ajustement de largeur.

  static void _addOptional(
    List<String> lines,
    String label,
    String? value,
    int width,
  ) => TicketTextPrimitives.addOptional(lines, label, value, width);

  static String _rule(int width) => TicketTextPrimitives.rule(width);

  static String _banner(String rawText, int width) =>
      TicketTextPrimitives.banner(rawText, width);

  static List<String> _centered(String text, int width) =>
      TicketTextPrimitives.centered(text, width);

  static List<String> _centeredWrapped(String text, int width) =>
      TicketTextPrimitives.centeredWrapped(text, width);

  static void _addPair(
    List<String> lines,
    String rawLabel,
    String rawValue,
    int width,
  ) => TicketTextPrimitives.addPair(lines, rawLabel, rawValue, width);

  static String _formatDate(DateTime at) => TicketTextPrimitives.formatDate(at);

  static String _formatTime(DateTime at) => TicketTextPrimitives.formatTime(at);

  static List<String> _wrapped(String text, int width) =>
      TicketTextPrimitives.wrapped(text, width);
}
