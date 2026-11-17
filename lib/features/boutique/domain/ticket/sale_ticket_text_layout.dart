import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sections.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sheet.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

/// Met le ticket de vente en **lignes de caractères**.
///
/// Frère de `TicketTextLayout` (le ticket de perception), et désormais son
/// jumeau d'aspect : même en-tête, même bloc référence/date/caissier, même
/// payeur, même « Montant reçu », même signature, même QR, même pied — tous
/// tirés de `TicketSections`. Ce qui lui reste propre, c'est le panier et la
/// preuve du comptant intégral (« Reste à payer » à zéro).
///
/// C'est le **seul** endroit où la mise en page du ticket de vente est décidée,
/// et le seul niveau réellement testable : aucun golden test n'existe dans ce
/// dépôt, et un flux ESC/POS ne se relit pas à l'œil.
abstract final class SaleTicketTextLayout {
  /// Largeur d'un ticket 80 mm — **celle du socle**, jamais une copie : une
  /// constante recopiée finirait par diverger d'une colonne, décalant les
  /// montants d'un seul des deux tickets qui sortent de la même imprimante.
  static const int defaultColumns = TicketTextLayout.defaultColumns;

  /// Le ticket **en texte nu** — la forme sur laquelle se vérifie « même
  /// contenu textuel entre l'aperçu et la thermique ».
  static List<String> render(
    SaleTicketModel model, {
    int columns = defaultColumns,
  }) => [for (final line in renderRich(model, columns: columns)) line.text];

  /// Le ticket en lignes **attribuées** (gras, QR), que consomment les deux
  /// renderers.
  static List<TicketLine> renderRich(
    SaleTicketModel model, {
    int columns = defaultColumns,
  }) {
    final sheet = TicketSheet(columns);
    final width = sheet.width;
    final lines = sheet.lines;
    final labels = model.labels;
    final rule = TicketTextPrimitives.rule(width);

    // ── L'établissement, puis la nature de la pièce : quelqu'un qui trie une
    // liasse en fin de journée doit l'identifier sans lire le corps.
    TicketSections.schoolHeader(
      sheet,
      model.school,
      schoolPhoneLabel: labels.schoolPhoneLabel,
      tillPhoneLabel: labels.tillPhoneLabel,
    );
    lines.add(rule);
    lines.addAll(
      TicketTextPrimitives.centered(labels.documentTitle.toUpperCase(), width),
    );
    lines.add(rule);

    // ── La pièce : son numéro définitif, sa date, son caissier.
    lines.addAll(
      TicketTextPrimitives.wrapped(
        '${labels.referenceLabel} ${model.receiptNumber}',
        width,
      ),
    );
    TicketSections.dateAndCashier(
      sheet,
      dateLabel: labels.dateLabel,
      enteredAtLabel: labels.enteredAtLabel,
      enteredAt: model.soldAt,
      issuedOn: model.receiptIssuedOn,
      cashierLabel: labels.cashierLabel,
      cashierFullName: model.cashierFullName,
    );
    lines.add(rule);

    // ── Le payeur : c'est LUI le sujet de la pièce, pas un élève. Le bloc
    // entier disparaît sur une vente anonyme.
    TicketSections.payer(
      sheet,
      payerLabel: labels.payerLabel,
      phoneLabel: labels.phoneLabel,
      fullName: model.payerFullName,
      phoneNumber: model.payerPhoneNumber,
    );

    // ── Le panier.
    sheet.emphasised(
      () => lines.addAll(
        TicketTextPrimitives.wrapped(labels.articlesLabel, width),
      ),
    );
    for (final line in model.lines) {
      TicketTextPrimitives.addPair(
        lines,
        '${line.quantity} x ${line.label}',
        TicketSections.formatAmount(line.lineTotalInCents, line.currency),
        width,
      );
      lines.addAll(TicketTextPrimitives.wrapped(_metaOf(line, labels), width));
      // Le bénéficiaire, sous son article, comme sur un cadeau : « pour qui »
      // plutôt que « qui paie ».
      final beneficiary = line.beneficiaryName?.trim();
      if (beneficiary != null && beneficiary.isNotEmpty) {
        lines.addAll(
          TicketTextPrimitives.wrapped(
            '${labels.beneficiaryPrefix} $beneficiary',
            width,
          ),
        );
      }
    }
    lines.add(rule);

    // ── L'argent. Le total du panier en devises de catalogue, puis ce qui est
    // entré dans le tiroir — les deux diffèrent dès qu'un franc paie un
    // article tarifé en dollars, et le taux le dit.
    TicketSections.addMoneyBag(lines, labels.totalLabel, model.totals, width);
    TicketSections.amountReceived(
      sheet,
      amountReceivedLabel: labels.amountReceivedLabel,
      rateLabel: labels.rateLabel,
      tenders: model.tenders,
    );
    // ⚠️ TOUJOURS imprimé, et toujours à zéro : la preuve visuelle du comptant
    // intégral (invariant I-5), une ligne par devise du panier.
    TicketSections.addMoneyBag(
      lines,
      labels.remainingLabel,
      model.remaining,
      width,
    );
    lines.add(rule);

    // La mention de non-remboursement : le seul levier de l'école quand
    // l'article est déjà parti.
    lines.addAll(
      TicketTextPrimitives.centeredWrapped(labels.noRefundNotice, width),
    );

    TicketSections.closing(
      sheet,
      signatureLabel: labels.signatureLabel,
      verificationNotice: labels.verificationNotice,
      verificationUrl: model.verificationUrl,
      thanksNotice: labels.thanksNotice,
      editorNotice: labels.editorNotice,
      editorSite: labels.editorSite,
    );

    return sheet.build();
  }

  /// « 15,00 $ /u - 1ère HUM - T. M » — et **sans séparateur orphelin** : un
  /// article à prix unique n'a ni niveau ni taille.
  static String _metaOf(SaleTicketLine line, SaleTicketLabels labels) {
    final parts = <String>[
      '${TicketSections.formatAmount(line.unitPriceInCents, line.currency)} '
          '${labels.unitSuffix}',
      if (line.levelLabel != null && line.levelLabel!.trim().isNotEmpty)
        line.levelLabel!.trim(),
      if (line.size != null && line.size!.trim().isNotEmpty)
        '${labels.sizePrefix} ${line.size!.trim()}',
    ];
    return parts.join(' - ');
  }
}
