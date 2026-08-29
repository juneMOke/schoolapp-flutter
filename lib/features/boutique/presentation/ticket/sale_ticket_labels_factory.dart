import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traduit les libellés fixes du ticket de vente.
///
/// Le modèle et son gabarit restent **purs** — aucun `BuildContext` — tout en
/// respectant l'interdiction des chaînes en dur : c'est ici, et seulement ici,
/// que la traduction entre.
SaleTicketLabels saleTicketLabelsOf(AppLocalizations l10n) => SaleTicketLabels(
  documentTitle: l10n.boutiqueTicketTitle,
  provisionalBanner: l10n.boutiqueTicketProvisionalBanner,
  provisionalNotice: l10n.boutiqueTicketProvisionalNotice,
  sealedNotice: l10n.boutiqueTicketSealedNotice,
  payerLabel: l10n.boutiqueTicketPayerLabel,
  phoneLabel: l10n.boutiqueTicketPhoneLabel,
  cashierLabel: l10n.boutiqueTicketCashierLabel,
  totalLabel: l10n.boutiqueTicketTotalLabel,
  cashReceivedLabel: l10n.boutiqueTicketCashReceivedLabel,
  remainingLabel: l10n.boutiqueTicketRemainingLabel,
  beneficiaryPrefix: l10n.boutiqueTicketBeneficiaryPrefix,
  sizePrefix: l10n.boutiqueTicketSizePrefix,
  unitSuffix: l10n.boutiqueTicketUnitSuffix,
  noRefundNotice: l10n.boutiqueTicketNoRefundNotice,
);
