import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traduit les libellés fixes du ticket de vente.
///
/// Le modèle et son gabarit restent **purs** — aucun `BuildContext` — tout en
/// respectant l'interdiction des chaînes en dur : c'est ici, et seulement ici,
/// que la traduction entre.
///
/// Les libellés communs à tous les tickets de caisse sont ceux du ticket de
/// perception (`ticket…`) : deux pièces de la même caisse disent la même chose,
/// et une retouche de traduction les suit toutes les deux.
SaleTicketLabels saleTicketLabelsOf(AppLocalizations l10n) => SaleTicketLabels(
  documentTitle: l10n.boutiqueTicketTitle,
  schoolPhoneLabel: l10n.ticketSchoolPhoneLabel,
  tillPhoneLabel: l10n.ticketTillPhoneLabel,
  referenceLabel: l10n.ticketReferenceLabel,
  dateLabel: l10n.ticketDateLabel,
  enteredAtLabel: l10n.ticketEnteredAtLabel,
  cashierLabel: l10n.ticketCashierLabel,
  payerLabel: l10n.ticketPayerLabel,
  phoneLabel: l10n.ticketPhoneLabel,
  articlesLabel: l10n.boutiqueTicketArticlesLabel,
  beneficiaryPrefix: l10n.boutiqueTicketBeneficiaryPrefix,
  sizePrefix: l10n.boutiqueTicketSizePrefix,
  unitSuffix: l10n.boutiqueTicketUnitSuffix,
  totalLabel: l10n.boutiqueTicketTotalLabel,
  amountReceivedLabel: l10n.ticketAmountReceivedLabel,
  rateLabel: l10n.ticketRateLabel,
  remainingLabel: l10n.boutiqueTicketRemainingLabel,
  noRefundNotice: l10n.boutiqueTicketNoRefundNotice,
  signatureLabel: l10n.ticketSignatureLabel,
  verificationNotice: l10n.ticketVerifyNotice,
  thanksNotice: l10n.ticketThanksNotice,
  editorNotice: l10n.ticketEditorNotice,
  editorSite: l10n.ticketEditorSite,
);
