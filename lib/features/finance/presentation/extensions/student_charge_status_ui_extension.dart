import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Représentation visuelle unique d'un statut de frais (spec Facturation §20).
///
/// Une seule source pilote partout la couleur du badge, le remplissage de la
/// barre de progression et l'icône (ligne, allocation, détail).
class FeeStatusVisuals {
  final Color color;
  final Color soft;
  final Color border;
  final IconData icon;

  const FeeStatusVisuals({
    required this.color,
    required this.soft,
    required this.border,
    required this.icon,
  });
}

extension StudentChargeStatusUiX on StudentChargeStatus {
  /// Source unique des teintes + icône (spec §20).
  FeeStatusVisuals get visuals => switch (this) {
    StudentChargeStatus.due => const FeeStatusVisuals(
      color: AppColors.feeStatusDue,
      soft: AppColors.feeStatusDueSoft,
      border: AppColors.feeStatusDueBorder,
      icon: Icons.error_outline_rounded,
    ),
    StudentChargeStatus.partial => const FeeStatusVisuals(
      color: AppColors.feeStatusPartial,
      soft: AppColors.feeStatusPartialSoft,
      border: AppColors.feeStatusPartialBorder,
      icon: Icons.schedule_rounded,
    ),
    StudentChargeStatus.paid => const FeeStatusVisuals(
      color: AppColors.feeStatusPaid,
      soft: AppColors.feeStatusPaidSoft,
      border: AppColors.feeStatusPaidBorder,
      icon: Icons.check_circle_outline_rounded,
    ),
  };

  /// Couleur sémantique du statut (badge / barre / icône).
  Color get badgeColor => visuals.color;

  /// Fond doux pour pastilles et fonds de badge.
  Color get softColor => visuals.soft;

  /// Bord assorti au fond doux.
  Color get borderColor => visuals.border;

  /// Icône sémantique du statut.
  IconData get icon => visuals.icon;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    StudentChargeStatus.due => l10n.studentChargeStatusDue,
    StudentChargeStatus.partial => l10n.studentChargeStatusPartial,
    StudentChargeStatus.paid => l10n.studentChargeStatusPaid,
  };
}

/// Dérivation cohérente du statut à partir du couple (attendu, payé) en cents.
///
/// Utile pour anticiper l'UI sans attendre un aller-retour backend (ex. impact
/// d'un encaissement en cours). Le backend reste la source de vérité persistée.
StudentChargeStatus feeStatusFromAmounts({
  required double expectedAmountInCents,
  required double amountPaidInCents,
}) {
  if (amountPaidInCents <= 0) {
    return StudentChargeStatus.due;
  }
  if (amountPaidInCents >= expectedAmountInCents) {
    return StudentChargeStatus.paid;
  }
  return StudentChargeStatus.partial;
}
