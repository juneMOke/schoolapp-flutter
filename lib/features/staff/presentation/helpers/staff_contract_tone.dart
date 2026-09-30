import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';

/// La couleur d'un statut de contrat, réutilisée partout où il s'affiche :
/// puce, filtre, carte, anneau de l'avatar.
class StaffContractTone {
  /// Teinte pleine (anneau, pastille, trait).
  final Color color;

  /// Voile de fond d'une puce ou d'un bloc.
  final Color soft;

  /// Encre d'un texte posé sur [soft] — distincte de [color] quand celle-ci
  /// n'y tient pas le contraste.
  final Color ink;
  final IconData icon;

  const StaffContractTone._(this.color, this.soft, this.ink, this.icon);

  /// Opacité du filet d'une période en vigueur : la teinte, adoucie.
  static const double _outlineAlpha = 0.4;

  /// Le filet d'une surface teintée par ce statut (période en vigueur).
  Color get outline => color.withValues(alpha: _outlineAlpha);

  static const StaffContractTone _permanent = StaffContractTone._(
    AppColors.staffPermanent,
    AppColors.staffPermanentSoft,
    AppColors.staffPermanentInk,
    Icons.verified_user_outlined,
  );
  static const StaffContractTone _vacataire = StaffContractTone._(
    AppColors.staffVacataire,
    AppColors.staffVacataireSoft,
    AppColors.staffVacataireInk,
    Icons.schedule,
  );
  static const StaffContractTone _conventionne = StaffContractTone._(
    AppColors.staffConventionne,
    AppColors.staffConventionneSoft,
    AppColors.staffConventionneInk,
    Icons.account_balance_outlined,
  );
  static const StaffContractTone _none = StaffContractTone._(
    AppColors.staffNoContract,
    AppColors.staffNoContractSoft,
    AppColors.staffNoContract,
    Icons.hourglass_empty,
  );

  /// `null` = aucun contrat en vigueur.
  static StaffContractTone of(StaffContractKind? kind) => switch (kind) {
    StaffContractKind.permanent => _permanent,
    StaffContractKind.vacataire => _vacataire,
    StaffContractKind.conventionne => _conventionne,
    null => _none,
  };

  static StaffContractTone ofFilter(StaffContractFilter filter) =>
      switch (filter) {
        StaffContractFilter.permanent => _permanent,
        StaffContractFilter.vacataire => _vacataire,
        StaffContractFilter.conventionne => _conventionne,
        StaffContractFilter.none => _none,
      };
}
