import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le verdict d'une classe de la simulation (R12), au seuil choisi.
///
/// Calculé à l'écran — le serveur donne effectif et restants, le seuil est un
/// réglage de lecture que l'adresse retient. Tout se compare **en produits
/// croisés d'entiers** : « 59,6 % » n'est jamais arrondi en « 60 % » pour
/// échapper au seuil.
enum RecoveryVerdict {
  unmanageable,
  fragile,
  tenable;

  /// `null` pour une classe sans effectif ou pour « Non affectés » : ni l'une
  /// ni l'autre n'a d'effectif à conserver.
  static RecoveryVerdict? of(RecoverySimulationRow row, int unmanageableBelow) {
    if (row.isUnassigned || row.headcount <= 0) return null;
    return ofCounts(row.remainingHeadcount, row.headcount, unmanageableBelow);
  }

  /// Le même verdict sur deux effectifs (la page entière, une classe).
  static RecoveryVerdict ofCounts(
    int remaining,
    int headcount,
    int unmanageableBelow,
  ) {
    // remaining / headcount < seuil / 100 ⇔ remaining × 100 < seuil × headcount
    final kept = remaining * 100;
    if (kept < unmanageableBelow * headcount) return unmanageable;
    final fragileBelow = unmanageableBelow + AppConstants.recoveryFragileBand;
    if (kept < fragileBelow * headcount) return fragile;
    return tenable;
  }

  String label(AppLocalizations l10n) => switch (this) {
    unmanageable => l10n.recoveryVerdictUnmanageable,
    fragile => l10n.recoveryVerdictFragile,
    tenable => l10n.recoveryVerdictTenable,
  };

  /// La couleur de surface (barre, liseré) — `REC_NIVEAU` de la maquette.
  Color get color => switch (this) {
    unmanageable => AppColors.error,
    fragile => AppColors.feeStatusPartial,
    tenable => AppColors.vertSavane,
  };

  /// La même couleur quand elle porte du texte sur fond clair.
  Color get ink => DashboardTones.encreLisible(color);

  Color get soft => switch (this) {
    unmanageable => AppColors.feeStatusDueSoft,
    fragile => AppColors.feeStatusPartialSoft,
    tenable => AppColors.feeStatusPaidSoft,
  };

  IconData get icon => switch (this) {
    unmanageable => Icons.warning_amber_rounded,
    fragile => Icons.schedule,
    tenable => Icons.check_circle_outline,
  };
}

/// La part conservée, en pourcentage **arrondi à l'inférieur** : ainsi
/// « 59 % » s'affiche sous un seuil de 60, jamais « 60 % » marqué ingérable.
/// 0 sans effectif.
int recoveryKeptPercent(int remaining, int headcount) =>
    headcount <= 0 ? 0 : (remaining * 100) ~/ headcount;
