import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traduit les libellés du ticket.
///
/// Point de passage unique entre `AppLocalizations` et le gabarit : c'est ce qui
/// permet au modèle et à son rendu de rester purs — testables sans widget, sans
/// `BuildContext`, sans données de locale à initialiser — tout en respectant
/// l'interdiction des chaînes en dur.
TicketLabels provisionalTicketLabels(AppLocalizations l10n) => TicketLabels(
  provisionalBanner: l10n.ticketProvisionalBanner,
  referenceLabel: l10n.ticketReferenceLabel,
  cashierLabel: l10n.ticketCashierLabel,
  studentLabel: l10n.ticketStudentLabel,
  matriculationLabel: l10n.ticketMatriculationLabel,
  classroomLabel: l10n.ticketClassroomLabel,
  amountReceivedLabel: l10n.ticketAmountReceivedLabel,
  allocationsLabel: l10n.ticketAllocationsLabel,
  advanceLabel: l10n.ticketAdvanceLabel,
  balanceLabel: l10n.ticketBalanceLabel,
  balanceReservation: l10n.ticketBalanceReservation,
  keepTicketNotice: l10n.ticketKeepNotice,
);
