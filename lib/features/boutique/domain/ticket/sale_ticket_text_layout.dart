import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

/// Met le ticket de vente en **lignes de caractères**.
///
/// Frère de `TicketTextLayout` (le ticket de perception) : même socle de
/// primitives, même largeur, même imprimante. Ce qu'il pose est différent —
/// aucune dette, aucun solde, aucun élève sujet — et c'est pourquoi c'est un
/// gabarit distinct plutôt qu'un drapeau sur l'autre.
///
/// C'est le **seul** endroit où la mise en page du ticket de vente est décidée,
/// et le seul niveau réellement testable : aucun golden test n'existe dans ce
/// dépôt, et un flux ESC/POS ne se relit pas à l'œil.
abstract final class SaleTicketTextLayout {
  /// Largeur d'un ticket 80 mm — **celle du socle**, jamais une copie : une
  /// constante recopiée finirait par diverger d'une colonne, décalant les
  /// montants d'un seul des deux tickets qui sortent de la même imprimante.
  static const int defaultColumns = TicketTextLayout.defaultColumns;

  static List<String> render(
    SaleTicketModel model, {
    int columns = defaultColumns,
  }) {
    final width = columns < 24 ? 24 : columns;
    final lines = <String>[];

    // ── L'établissement, puis la nature de la pièce. Quelqu'un qui trie une
    // liasse en fin de journée doit l'identifier sans lire le corps.
    lines.addAll(
      TicketTextPrimitives.centered(model.schoolName.toUpperCase(), width),
    );
    final address = model.schoolAddress?.trim();
    if (address != null && address.isNotEmpty) {
      lines.addAll(TicketTextPrimitives.centered(address, width));
    }
    lines.add(TicketTextPrimitives.rule(width));
    lines.addAll(
      TicketTextPrimitives.centered(
        model.labels.documentTitle.toUpperCase(),
        width,
      ),
    );
    lines.addAll(TicketTextPrimitives.centered(model.reference, width));

    // Le bandeau, HAUT et pleine largeur : la dissemblance entre une pièce
    // provisoire et une pièce scellée doit se lire avant le contenu, y compris
    // par quelqu'un qui lit peu le français.
    if (model.isProvisional) {
      lines.add(
        TicketTextPrimitives.banner(model.labels.provisionalBanner, width),
      );
    }
    lines.add(TicketTextPrimitives.rule(width));

    TicketTextPrimitives.addPair(
      lines,
      TicketTextPrimitives.formatDate(model.soldAt),
      TicketTextPrimitives.formatTime(model.soldAt),
      width,
    );
    // Sur une pièce non scellée, l'imputabilité HUMAINE remplace l'imputabilité
    // cryptographique : sans caissier nommé, un écart de tiroir en fin de
    // journée ne s'arbitre pas.
    TicketTextPrimitives.addOptional(
      lines,
      model.labels.cashierLabel,
      model.cashierFullName,
      width,
    );
    lines.add(TicketTextPrimitives.rule(width));

    // ── Le payeur : c'est LUI le sujet de la pièce, pas un élève.
    lines.addAll(
      TicketTextPrimitives.wrapped(
        '${model.labels.payerLabel} ${model.payerFullName.toUpperCase()}',
        width,
      ),
    );
    TicketTextPrimitives.addOptional(
      lines,
      model.labels.phoneLabel,
      model.payerPhoneNumber,
      width,
    );
    lines.add(TicketTextPrimitives.rule(width));

    // ── Le panier.
    for (final line in model.lines) {
      TicketTextPrimitives.addPair(
        lines,
        '${line.quantity} x ${line.label}',
        _amount(line.lineTotalInCents, model.currency),
        width,
      );
      lines.addAll(TicketTextPrimitives.wrapped(_metaOf(line, model), width));
      // Le bénéficiaire s'écrit indenté, comme sur un cadeau : « pour qui »
      // plutôt que « qui paie ».
      final beneficiary = line.beneficiaryName?.trim();
      if (beneficiary != null && beneficiary.isNotEmpty) {
        lines.addAll(
          TicketTextPrimitives.wrapped(
            '  ${model.labels.beneficiaryPrefix} $beneficiary',
            width,
          ),
        );
      }
    }
    lines.add(TicketTextPrimitives.rule(width));

    // ── L'argent. Les trois lignes sont des FAITS, sans réserve : il n'y a
    // aucune imputation à arbitrer, aucun solde incertain.
    TicketTextPrimitives.addPair(
      lines,
      model.labels.totalLabel,
      _amount(model.totalInCents, model.currency),
      width,
    );
    TicketTextPrimitives.addPair(
      lines,
      model.labels.cashReceivedLabel,
      _amount(model.cashReceivedInCents, model.currency),
      width,
    );
    // ⚠️ TOUJOURS imprimé, et toujours à zéro : c'est la preuve visuelle du
    // comptant intégral (invariant I-5). L'escamoter parce qu'il vaut zéro
    // retirerait au porteur la seule ligne qui atteste qu'il ne doit rien.
    TicketTextPrimitives.addPair(
      lines,
      model.labels.remainingLabel,
      _amount(model.remainingInCents, model.currency),
      width,
    );

    lines.add(TicketTextPrimitives.rule(width));
    lines.addAll(
      TicketTextPrimitives.centeredWrapped(
        model.isProvisional
            ? model.labels.provisionalNotice
            : model.labels.sealedNotice,
        width,
      ),
    );
    // La mention de non-remboursement : le seul levier de l'école quand
    // l'article est déjà parti.
    lines.addAll(
      TicketTextPrimitives.centeredWrapped(model.labels.noRefundNotice, width),
    );

    return lines;
  }

  /// « 15.00 $ /u · 1ère HUM · T. M » — et **sans séparateur orphelin**.
  ///
  /// Un article à prix unique n'a ni niveau ni taille : il ne doit pas traîner
  /// un « · » qui ferait chercher une information absente.
  static String _metaOf(SaleTicketLine line, SaleTicketModel model) {
    final parts = <String>[
      '${_amount(line.unitPriceInCents, model.currency)} ${model.labels.unitSuffix}',
      if (line.levelLabel != null && line.levelLabel!.trim().isNotEmpty)
        line.levelLabel!.trim(),
      if (line.size != null && line.size!.trim().isNotEmpty)
        '${model.labels.sizePrefix} ${line.size!.trim()}',
    ];
    return parts.join(' - ');
  }

  /// Le montant, translittéré pour l'imprimante.
  ///
  /// Format de la spec boutique — « 35.00 $ », point décimal et symbole — et non
  /// celui du ticket de perception (« 1 234,56 CDF »). ⚠️ Les deux tickets
  /// sortent de la même imprimante : l'écart de format est **assumé et à
  /// arbitrer**, il est signalé au plan.
  static String _amount(int cents, String currency) => TicketCharset.printable(
    // Espace ORDINAIRE : le ticket part sur une thermique, et le parc a
    // tranché d'éviter l'insécable (`TicketTextLayout.formatAmount`).
    BoutiqueMoneyFormat.exact(cents, currency, space: MoneyFormat.thermalSpace),
  );
}
