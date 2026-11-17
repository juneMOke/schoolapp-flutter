import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sections.dart';

/// Une ligne du ticket de vente.
class SaleTicketLine extends Equatable {
  final String label;
  final int quantity;
  final int unitPriceInCents;
  final int lineTotalInCents;

  /// La devise de CETTE ligne : c'est l'article qui est tarifé dans une unité,
  /// donc un panier peut en mêler deux.
  final String currency;

  /// Niveau qui a résolu le prix — absent sur un article à prix unique, où
  /// aucun niveau n'entre dans le calcul.
  final String? levelLabel;

  /// Taille remise, sans effet sur le montant (invariant I-3).
  final String? size;

  /// L'enfant à qui l'article est destiné, `null` en walk-in.
  final String? beneficiaryName;

  const SaleTicketLine({
    required this.label,
    required this.quantity,
    required this.unitPriceInCents,
    required this.lineTotalInCents,
    required this.currency,
    this.levelLabel,
    this.size,
    this.beneficiaryName,
  });

  @override
  List<Object?> get props => [
    label,
    quantity,
    unitPriceInCents,
    lineTotalInCents,
    currency,
    levelLabel,
    size,
    beneficiaryName,
  ];
}

/// Libellés fixes du ticket de vente, injectés depuis `AppLocalizations`.
///
/// Le modèle et son rendu restent **purs** — aucun `BuildContext` — tout en
/// respectant l'interdiction des chaînes en dur : c'est l'appelant qui traduit,
/// le gabarit qui arrange. Les libellés communs à tous les tickets de caisse
/// (en-tête, date, payeur, montant reçu, signature, pied) sont ceux du ticket
/// de perception : deux pièces de la même caisse disent la même chose.
class SaleTicketLabels extends Equatable {
  /// « REÇU DE VENTE — BOUTIQUE », imprimé en tête.
  final String documentTitle;

  final String schoolPhoneLabel;
  final String tillPhoneLabel;
  final String referenceLabel;
  final String dateLabel;
  final String enteredAtLabel;
  final String cashierLabel;
  final String payerLabel;
  final String phoneLabel;

  /// « Articles », titre du panier.
  final String articlesLabel;

  /// Préfixe d'une ligne de bénéficiaire : « pour ».
  final String beneficiaryPrefix;

  /// Abréviation de taille : « T. ».
  final String sizePrefix;

  /// Suffixe de prix unitaire : « /u ».
  final String unitSuffix;

  /// « TOTAL » — ce que le panier vaut, en devises de catalogue.
  final String totalLabel;

  /// « Montant reçu » — ce qui est entré dans le tiroir.
  final String amountReceivedLabel;
  final String rateLabel;

  /// « Reste à payer » — **toujours imprimé**, et toujours à zéro : c'est la
  /// preuve visuelle du comptant intégral (invariant I-5).
  final String remainingLabel;

  /// « Aucun remboursement après remise de l'article. »
  final String noRefundNotice;

  final String signatureLabel;
  final String verificationNotice;
  final String thanksNotice;
  final String editorNotice;
  final String editorSite;

  const SaleTicketLabels({
    required this.documentTitle,
    required this.schoolPhoneLabel,
    required this.tillPhoneLabel,
    required this.referenceLabel,
    required this.dateLabel,
    required this.enteredAtLabel,
    required this.cashierLabel,
    required this.payerLabel,
    required this.phoneLabel,
    required this.articlesLabel,
    required this.beneficiaryPrefix,
    required this.sizePrefix,
    required this.unitSuffix,
    required this.totalLabel,
    required this.amountReceivedLabel,
    required this.rateLabel,
    required this.remainingLabel,
    required this.noRefundNotice,
    required this.signatureLabel,
    required this.verificationNotice,
    required this.thanksNotice,
    required this.editorNotice,
    required this.editorSite,
  });

  @override
  List<Object?> get props => [
    documentTitle,
    schoolPhoneLabel,
    tillPhoneLabel,
    referenceLabel,
    dateLabel,
    enteredAtLabel,
    cashierLabel,
    payerLabel,
    phoneLabel,
    articlesLabel,
    beneficiaryPrefix,
    sizePrefix,
    unitSuffix,
    totalLabel,
    amountReceivedLabel,
    rateLabel,
    remainingLabel,
    noRefundNotice,
    signatureLabel,
    verificationNotice,
    thanksNotice,
    editorNotice,
    editorSite,
  ];
}

/// Le ticket de vente boutique — **la preuve de paiement remise au comptoir**.
///
/// Il ne sort qu'avec le **numéro définitif** du reçu de vente (`ETL-RV-…`),
/// comme le ticket de perception : plus de ticket provisoire, donc plus de
/// mention « provisoire » ni de référence `PROV-` sur le papier.
///
/// ⚠️ **Distinct du ticket de perception** (`TicketReceiptModel`), qui atteste
/// un versement sur des créances scolaires et porte une répartition, un solde et
/// un élève. Celui-ci n'a ni dette, ni reste, ni sujet élève : son sujet est le
/// **payeur**, et les bénéficiaires vivent sur les lignes. Les deux partagent en
/// revanche tous les blocs de caisse (`TicketSections`).
class SaleTicketModel extends Equatable {
  final TicketSchoolHeader school;

  /// Le numéro définitif du reçu de vente.
  final String receiptNumber;

  /// L'heure métier de la vente, à l'heure de l'école.
  final DateTime soldAt;

  /// Le jour d'émission du reçu scellé — la date principale du ticket. `null`
  /// tant que le serveur ne l'a pas dit : la date de la vente la remplace.
  final DateTime? receiptIssuedOn;

  /// L'URL du QR de vérification ; `null` = ticket sans QR.
  final String? verificationUrl;

  final String? cashierFullName;

  /// Le payeur, **quand il y en a un** — `null`, jamais `''`, sur une vente
  /// anonyme : le bloc payeur disparaît alors entier.
  final String? payerFullName;
  final String? payerPhoneNumber;
  final List<SaleTicketLine> lines;

  /// Ce qui est entré dans le tiroir, une ligne par règlement (devise posée,
  /// taux gelé, devise de catalogue réglée). C'est le « Montant reçu ».
  final List<TicketTenderLine> tenders;
  final SaleTicketLabels labels;

  const SaleTicketModel({
    required this.school,
    required this.receiptNumber,
    required this.soldAt,
    this.receiptIssuedOn,
    this.verificationUrl,
    this.cashierFullName,
    this.payerFullName,
    this.payerPhoneNumber,
    required this.lines,
    required this.tenders,
    required this.labels,
  });

  /// Le total, **par devise de catalogue** — dérivé des lignes. Un panier qui
  /// règle 450,00 $ d'uniformes et 90 000 FC de manuels n'a pas de total
  /// unique : les additionner imprimerait un chiffre qui n'est l'argent de
  /// personne.
  MoneyBag get totals => MoneyBag.sumBy(
    lines,
    (line) => Money.parse(line.lineTotalInCents, line.currency),
  );

  /// Toujours zéro, **dans chaque devise du panier** (invariant I-5). Exposé
  /// comme une valeur plutôt qu'écrit en dur dans le gabarit : ce qui
  /// s'imprime est un fait du modèle, pas une constante de mise en page.
  MoneyBag get remaining =>
      MoneyBag.of([for (final t in totals.entries) Money(0, t.currency)]);

  @override
  List<Object?> get props => [
    school,
    receiptNumber,
    soldAt,
    receiptIssuedOn,
    verificationUrl,
    cashierFullName,
    payerFullName,
    payerPhoneNumber,
    lines,
    tenders,
    labels,
  ];
}
