import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'une justification montre de son état : un libellé et une teinte,
/// empruntée aux présences (acceptée = présent, refusée = absent).
abstract final class JustificationLabels {
  static String status(AppLocalizations l10n, AttendanceJustification j) {
    if (j.isSending) return l10n.justificationStatusSending;
    return switch (j.status) {
      JustificationStatus.pending => l10n.justificationStatusPending,
      JustificationStatus.accepted => l10n.justificationStatusAccepted,
      JustificationStatus.rejected => l10n.justificationStatusRejected,
      JustificationStatus.unknown => l10n.justificationStatusUnknown,
    };
  }

  static PresenceTone tone(AttendanceJustification j) {
    if (j.isSending) return PresenceTone.of(PresenceStatus.none);
    return PresenceTone.of(switch (j.status) {
      JustificationStatus.pending => PresenceStatus.late,
      JustificationStatus.accepted => PresenceStatus.present,
      JustificationStatus.rejected => PresenceStatus.absent,
      JustificationStatus.unknown => PresenceStatus.none,
    });
  }

  static String acceptBlock(
    AppLocalizations l10n,
    JustificationAcceptBlock block,
  ) => switch (block) {
    JustificationAcceptBlock.notAnAbsence =>
      l10n.justificationBlockedNotAnAbsence,
    JustificationAcceptBlock.monthClosed =>
      l10n.justificationBlockedMonthClosed,
  };

  static String refusal(AppLocalizations l10n, JustificationRefusal refusal) =>
      switch (refusal) {
        JustificationRefusal.noAuthor => l10n.justificationRefusalNoAuthor,
        JustificationRefusal.forbidden => l10n.justificationRefusalForbidden,
        JustificationRefusal.rejected => l10n.justificationRefusalRejected,
        JustificationRefusal.notSent => l10n.justificationRefusalNotSent,
      };

  /// « Nom Post-nom Prénom », ou l'élève inconnu du roster.
  static String student(AppLocalizations l10n, AttendanceJustification j) =>
      j.studentName.isEmpty ? l10n.justificationUnknownStudent : j.studentName;

  /// « 14 oct. 2026 » depuis un instant.
  static String? date(MaterialLocalizations dates, DateTime? instant) =>
      instant == null ? null : dates.formatMediumDate(instant.toLocal());
}
