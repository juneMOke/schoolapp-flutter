import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Statuts d'un jour scolaire couverts par les donnees calculees en local.
///
/// NB : la spec prevoit aussi un statut « retard », mais le calcul local
/// (`StudentAttendanceStats`) ne le distingue pas (seulement present /
/// justifiee / injustifiee) — il est donc volontairement absent ici.
enum AttendanceDayStatus { present, justified, unjustified }

extension AttendanceDayStatusX on AttendanceDayStatus {
  /// Couleur d'accent (texte / icone / liseret).
  Color get color => switch (this) {
    AttendanceDayStatus.present => AppColors.vertSavane,
    AttendanceDayStatus.justified => AppColors.warning,
    AttendanceDayStatus.unjustified => AppColors.error,
  };

  /// Fond doux (pastilles, medaillon d'icone KPI).
  Color get softColor => color.withValues(alpha: 0.12);

  /// Teinte de cellule (segment de la barre de repartition).
  Color get cellColor => color.withValues(alpha: 0.32);

  IconData get icon => switch (this) {
    AttendanceDayStatus.present => Icons.check_rounded,
    AttendanceDayStatus.justified => Icons.event_busy_rounded,
    AttendanceDayStatus.unjustified => Icons.block_rounded,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AttendanceDayStatus.present => l10n.presenceStatusPresent,
    AttendanceDayStatus.justified => l10n.presenceStatusJustified,
    AttendanceDayStatus.unjustified => l10n.presenceStatusUnjustified,
  };

  /// Statut d'une absence selon son motif — le verdict vient d'
  /// [isUnjustifiedAbsence], seul endroit où la règle vit.
  ///
  /// ⚠️ Une absence **sans motif** est désormais injustifiée, et non plus
  /// justifiée par défaut : elle l'était ici et dans le calcul offline, alors
  /// que le tableau de bord la comptait déjà à l'inverse. Deux écrans du même
  /// produit répondaient le contraire sur la même journée.
  static AttendanceDayStatus forAbsenceReason(AbsenceReason? reason) =>
      isUnjustifiedAbsence(reason)
      ? AttendanceDayStatus.unjustified
      : AttendanceDayStatus.justified;
}
