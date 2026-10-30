import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/payment_correction_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traduit les libellés du ticket d'annulation — même rôle que
/// `provisionalTicketLabels` pour le ticket de caisse.
TicketCancellationLabels cancellationTicketLabels(AppLocalizations l10n) =>
    TicketCancellationLabels(
      title: l10n.ticketCancellationTitle,
      receiptLabel: l10n.ticketCancellationReceiptLabel,
      cancelledMark: l10n.ticketCancellationMark,
      issuedAtLabel: l10n.ticketCancellationIssuedAtLabel,
      amountLabel: l10n.ticketCancellationAmountLabel,
      cancelledAtLabel: l10n.ticketCancellationCancelledAtLabel,
      reasonLabel: l10n.ticketCancellationReasonLabel,
      detailLabel: l10n.ticketCancellationDetailLabel,
      cashReturnedLabel: l10n.ticketCancellationCashReturnedLabel,
      yes: l10n.ticketCancellationYes,
      no: l10n.ticketCancellationNo,
      cancelledByLabel: l10n.ticketCancellationByLabel,
      classroomLabel: l10n.ticketClassroomLabel,
      schoolPhoneLabel: l10n.ticketSchoolPhoneLabel,
      tillPhoneLabel: l10n.ticketTillPhoneLabel,
      reasons: {
        for (final reason in PaymentCorrectionReason.values)
          reason.code: paymentCorrectionReasonLabel(reason, l10n),
      },
    );
