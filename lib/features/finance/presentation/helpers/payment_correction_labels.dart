import 'package:school_app_flutter/features/finance/domain/entities/payment_correction_summary.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_error_codes.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le libellé d'un motif, dans la langue de l'écran.
String paymentCorrectionReasonLabel(
  PaymentCorrectionReason reason,
  AppLocalizations l10n,
) => switch (reason) {
  PaymentCorrectionReason.refunded => l10n.paymentCorrectionReasonRefunded,
  PaymentCorrectionReason.duplicate => l10n.paymentCorrectionReasonDuplicate,
  PaymentCorrectionReason.wrongDevice =>
    l10n.paymentCorrectionReasonWrongDevice,
  PaymentCorrectionReason.wrongAmount =>
    l10n.paymentCorrectionReasonWrongAmount,
  PaymentCorrectionReason.wrongAllocation =>
    l10n.paymentCorrectionReasonWrongAllocation,
  PaymentCorrectionReason.wrongStudent =>
    l10n.paymentCorrectionReasonWrongStudent,
  PaymentCorrectionReason.other => l10n.paymentCorrectionReasonOther,
};

/// Le motif d'une correction enregistrée, précision comprise : « Mauvais
/// montant — Saisi 150 $ au lieu de 50 $ ».
String paymentCorrectionMotive(
  PaymentCorrectionSummary correction,
  AppLocalizations l10n,
) {
  final reason = PaymentCorrectionReason.fromCode(correction.reasonCode);
  final label = reason == null
      ? correction.reasonCode
      : paymentCorrectionReasonLabel(reason, l10n);
  final detail = correction.reason?.trim();
  return (detail == null || detail.isEmpty) ? label : '$label — $detail';
}

/// Le récit d'une annulation posée par le SERVEUR (B5) : « Versement annulé le
/// 26 sept. 2026 par Moke Junior. Motif : Mauvais montant — Saisi 150 \$ au
/// lieu de 50 \$ ». `null` tant que la date n'est pas connue.
String? paymentServerCancellationNotice({
  required String? date,
  required String? byName,
  required String? reasonCode,
  required String? reason,
  required AppLocalizations l10n,
}) {
  if (date == null) return null;
  final name = byName?.trim();
  final head = (name == null || name.isEmpty)
      ? l10n.paymentServerCancelledNotice(date)
      : l10n.paymentServerCancelledByNotice(date, name);
  final known = PaymentCorrectionReason.fromCode(reasonCode);
  final label = known == null
      ? reasonCode?.trim()
      : paymentCorrectionReasonLabel(known, l10n);
  final detail = reason?.trim();
  final motive = [
    if (label != null && label.isNotEmpty) label,
    if (detail != null && detail.isNotEmpty) detail,
  ].join(' — ');
  return motive.isEmpty
      ? head
      : '$head ${l10n.paymentCancellationMotive(motive)}';
}

/// La pastille d'une ligne de versement visée par une correction, `null`
/// quand il n'y a rien à dire.
String? paymentCorrectionBadge(
  PaymentCorrectionSummary? correction,
  AppLocalizations l10n,
) => switch (correction?.status) {
  PaymentCorrectionStatus.pending => l10n.paymentCorrectionPendingBadge,
  PaymentCorrectionStatus.localOnly => l10n.paymentCorrectionLocalBadge,
  PaymentCorrectionStatus.rejected => l10n.paymentCorrectionRejectedBadge,
  PaymentCorrectionStatus.applied || null => null,
};

/// La phrase du détail d'un versement visé par une correction, `null` quand
/// l'annulation serveur dit déjà tout.
String? paymentCorrectionNotice(
  PaymentCorrectionSummary? correction,
  AppLocalizations l10n,
) {
  if (correction == null) return null;
  return switch (correction.status) {
    PaymentCorrectionStatus.pending => l10n.paymentCorrectionPendingNotice(
      paymentCorrectionMotive(correction, l10n),
    ),
    PaymentCorrectionStatus.localOnly => l10n.paymentCorrectionLocalNotice(
      paymentCorrectionMotive(correction, l10n),
    ),
    PaymentCorrectionStatus.rejected =>
      correction.errorCode == FinanceErrorCodes.paymentAlreadyCorrected
          ? l10n.paymentCorrectionAlreadyCorrectedNotice
          : l10n.paymentCorrectionRejectedNotice(correction.errorCode ?? '—'),
    PaymentCorrectionStatus.applied => null,
  };
}
