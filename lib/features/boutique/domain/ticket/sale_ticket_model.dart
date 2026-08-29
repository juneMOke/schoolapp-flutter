import 'package:equatable/equatable.dart';

/// Une ligne du ticket de vente.
class SaleTicketLine extends Equatable {
  final String label;
  final int quantity;
  final int unitPriceInCents;
  final int lineTotalInCents;

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
    levelLabel,
    size,
    beneficiaryName,
  ];
}

/// Libellés fixes du ticket de vente, injectés depuis `AppLocalizations`.
///
/// Le modèle et son rendu restent **purs** — aucun `BuildContext`, aucune
/// dépendance Flutter — tout en respectant l'interdiction des chaînes en dur :
/// c'est l'appelant qui traduit, le gabarit qui arrange.
class SaleTicketLabels extends Equatable {
  /// « REÇU DE VENTE — BOUTIQUE », imprimé en tête.
  final String documentTitle;

  /// « *** DOCUMENT PROVISOIRE *** » — le bandeau d'une pièce non scellée.
  final String provisionalBanner;

  /// « Reçu définitif scellé à la synchronisation. »
  final String provisionalNotice;

  /// « Reçu scellé — vaut quittance », quand le serveur a déjà répondu.
  final String sealedNotice;

  final String payerLabel;
  final String phoneLabel;
  final String cashierLabel;
  final String totalLabel;

  /// « Espèces reçues ».
  final String cashReceivedLabel;

  /// « Reste à payer » — **toujours imprimé**, et toujours à zéro : c'est la
  /// preuve visuelle du comptant intégral (invariant I-5).
  final String remainingLabel;

  /// Préfixe d'une ligne de bénéficiaire : « ↳ pour ».
  final String beneficiaryPrefix;

  /// Abréviation de taille : « T. ».
  final String sizePrefix;

  /// Suffixe de prix unitaire : « /u ».
  final String unitSuffix;

  /// « Aucun remboursement après remise de l'article. »
  final String noRefundNotice;

  const SaleTicketLabels({
    required this.documentTitle,
    required this.provisionalBanner,
    required this.provisionalNotice,
    required this.sealedNotice,
    required this.payerLabel,
    required this.phoneLabel,
    required this.cashierLabel,
    required this.totalLabel,
    required this.cashReceivedLabel,
    required this.remainingLabel,
    required this.beneficiaryPrefix,
    required this.sizePrefix,
    required this.unitSuffix,
    required this.noRefundNotice,
  });

  @override
  List<Object?> get props => [
    documentTitle,
    provisionalBanner,
    provisionalNotice,
    sealedNotice,
    payerLabel,
    phoneLabel,
    cashierLabel,
    totalLabel,
    cashReceivedLabel,
    remainingLabel,
    beneficiaryPrefix,
    sizePrefix,
    unitSuffix,
    noRefundNotice,
  ];
}

/// Le ticket de vente boutique — **la preuve de paiement remise au comptoir**.
///
/// C'est ce que le front produit, immédiatement et hors ligne : le reçu scellé,
/// lui, est rendu par le serveur au push. Les deux coexistent, et le ticket dit
/// **lequel des deux** le porteur tient.
///
/// ⚠️ **Distinct du ticket de perception** (`TicketReceiptModel`), qui atteste
/// un versement sur des créances scolaires et porte une répartition, un solde et
/// un élève. Celui-ci n'a ni dette, ni reste, ni sujet élève : son sujet est le
/// **payeur**, et les bénéficiaires vivent sur les lignes.
class SaleTicketModel extends Equatable {
  final String schoolName;
  final String? schoolAddress;

  /// Numéro de la pièce : provisoire tant que le serveur n'a pas scellé.
  final String reference;

  /// Vrai tant que le reçu n'est pas scellé — hors ligne, ou ACK sans document.
  final bool isProvisional;

  final DateTime soldAt;
  final String? cashierFullName;
  final String payerFullName;
  final String? payerPhoneNumber;
  final List<SaleTicketLine> lines;
  final int totalInCents;
  final String currency;
  final SaleTicketLabels labels;

  const SaleTicketModel({
    required this.schoolName,
    this.schoolAddress,
    required this.reference,
    required this.isProvisional,
    required this.soldAt,
    this.cashierFullName,
    required this.payerFullName,
    this.payerPhoneNumber,
    required this.lines,
    required this.totalInCents,
    required this.currency,
    required this.labels,
  });

  /// Le montant reçu **est** le total : comptant intégral, en une fois.
  ///
  /// Il n'y a donc ni champ de saisie, ni calcul de monnaie, ni écart possible —
  /// et c'est pourquoi le reste imprimé vaut toujours zéro.
  int get cashReceivedInCents => totalInCents;

  /// Toujours zéro (invariant I-5). Exposé comme une valeur plutôt qu'écrit en
  /// dur dans le gabarit : ce qui s'imprime est un fait du modèle, pas une
  /// constante de mise en page.
  int get remainingInCents => 0;

  @override
  List<Object?> get props => [
    schoolName,
    schoolAddress,
    reference,
    isProvisional,
    soldAt,
    cashierFullName,
    payerFullName,
    payerPhoneNumber,
    lines,
    totalInCents,
    currency,
    labels,
  ];
}
