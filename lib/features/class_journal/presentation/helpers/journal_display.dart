import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/avatar_palette.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'apparence d'un statut de séance : jamais la couleur seule — une icône et
/// un libellé l'accompagnent toujours. Les encres tiennent 4,5:1 sur leur voile
/// (le gris de la spec, à 3,7:1, est remplacé par le texte secondaire).
({IconData icon, Color color, String label}) journalStatusVisual(
  JournalStatus status,
  AppLocalizations l10n,
) => switch (status) {
  JournalStatus.filled => (
    icon: Icons.check_circle_outline_rounded,
    color: AppColors.vertSavane,
    label: l10n.journalStatusFilled,
  ),
  JournalStatus.toPrepare => (
    icon: Icons.schedule_rounded,
    color: AppColors.textSecondary,
    label: l10n.journalStatusToPrepare,
  ),
  JournalStatus.missing => (
    icon: Icons.error_outline_rounded,
    color: AppColors.feeStatusPartialInk,
    label: l10n.journalStatusMissing,
  ),
  JournalStatus.rejected => (
    icon: Icons.report_gmailerrorred_rounded,
    color: AppColors.error,
    label: l10n.journalStatusRejected,
  ),
};

/// `08:20:00` → `08:20`.
String journalHhmm(String time) =>
    time.length >= 5 ? time.substring(0, 5) : time;

/// « 07:30 – 08:20 » ; « — » pour un créneau disparu de la grille.
String journalSlotRange(JournalLine line, AppLocalizations l10n) =>
    switch (line.slot) {
      final slot? => l10n.journalSlotRange(
        journalHhmm(slot.startTime),
        journalHhmm(slot.endTime),
      ),
      null => l10n.journalEmptyCell,
    };

/// « 1re », « 2e »… ; « — » pour un créneau disparu de la grille.
String journalRankLabel(JournalLine line, AppLocalizations l10n) =>
    switch (line.slot) {
      final slot? => l10n.journalRank(slot.order),
      null => l10n.journalEmptyCell,
    };

/// Le sur-titre d'une modale de séance : « 1re heure · 07:30 – 08:20 ·
/// date », la date seule pour un créneau disparu.
String journalEntryEyebrow(
  JournalLine line,
  DateTime date,
  AppLocalizations l10n,
) => switch (line.slot) {
  final slot? => l10n.journalEntryEyebrow(
    l10n.journalRank(slot.order),
    journalSlotRange(line, l10n),
    date,
  ),
  null => l10n.journalEntryEyebrowNoSlot(date),
};

/// Le toast d'un enregistrement : « Séance de 1re heure enregistrée ».
String journalSavedMessage(JournalLine line, AppLocalizations l10n) =>
    switch (line.slot) {
      final slot? => l10n.journalSaved(l10n.journalRank(slot.order)),
      null => l10n.journalSavedNoSlot,
    };

/// La couleur d'un cours (liséré) : stable, tirée de son identifiant.
Color journalCourseColor(JournalLine line) =>
    AvatarPalette.colorFor(line.coursId);

/// La phrase lue par un lecteur d'écran pour une séance : rang, cours,
/// statut, puis chaque champ rempli — la ligne se lit comme elle se voit.
String journalLineSemantics(JournalLine line, AppLocalizations l10n) {
  final status = journalStatusVisual(line.status, l10n).label;
  final head = switch (line.slot) {
    final slot? => l10n.journalLineSemantics(
      l10n.journalRank(slot.order),
      line.subjectLabel,
      line.classroomLabel,
      status,
    ),
    null => l10n.journalLineSemanticsNoSlot(
      line.subjectLabel,
      line.classroomLabel,
      status,
    ),
  };
  final fields = line.entry?.fields ?? JournalFields.empty;
  return [
    head,
    for (final field in JournalField.values)
      if (field.valueOf(fields).trim().isNotEmpty)
        l10n.journalFieldSemantics(field.label(l10n), field.valueOf(fields)),
  ].join('. ');
}
