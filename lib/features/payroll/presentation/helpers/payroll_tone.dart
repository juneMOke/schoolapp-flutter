import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_card_tabs.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';

/// La teinte d'un statut de paie, prise aux sens partagés des tableaux de
/// bord ([DashboardSense]) : brouillon neutre, soumise en attente (ocre),
/// versée encaissée (vert), alerte manquante (rouge).
///
/// La paie validée garde son jeton propre, `payrollValidated` : l'aubergine
/// des actes administratifs, qu'aucun autre sens ne porte (décision du
/// 2026-10-27, à l'essai).
class PayrollTone {
  /// L'accent, pour une surface : point, filet, segment, liseré.
  final Color color;

  /// Le voile d'un bandeau ou d'une pastille.
  final Color soft;

  /// L'encre lisible sur [soft] et sur une carte blanche.
  final Color ink;

  const PayrollTone._(this.color, this.soft, this.ink);

  /// Force du voile d'une pastille ou d'un bandeau, en % de l'accent.
  static const int softPercent = 10;

  static PayrollTone _sense(Color accent) {
    final soft = DashboardTones.teinte(accent, softPercent);
    return PayrollTone._(
      accent,
      soft,
      DashboardTones.encreLisibleSur(accent, soft),
    );
  }

  static const PayrollTone draft = PayrollTone._(
    AppColors.textMuted,
    AppColors.surfaceAlt,
    AppColors.textMutedAa,
  );
  static final PayrollTone submitted = _sense(DashboardSense.attente);
  static const PayrollTone validated = PayrollTone._(
    AppColors.payrollValidated,
    AppColors.payrollValidatedSoft,
    AppColors.payrollValidatedInk,
  );
  static final PayrollTone paid = _sense(DashboardSense.encaisse);

  /// Une retenue, un refus, une absence signalée.
  static final PayrollTone alert = _sense(DashboardSense.manquant);

  /// Le mois en cours, cerné dans une liste ou une série : la marque.
  static final PayrollTone current = _sense(DashboardSense.marque);

  /// Un geste en vol se lit dans la teinte de là où il va.
  static PayrollTone of(PayrollPhase phase) => switch (phase) {
    PayrollPhase.draft || PayrollPhase.returning => draft,
    PayrollPhase.submitted || PayrollPhase.submitting => submitted,
    PayrollPhase.validated ||
    PayrollPhase.validating ||
    PayrollPhase.reopening => validated,
    PayrollPhase.paid => paid,
  };

  EteeloTabBadge badge(String label) => (label: label, soft: soft, ink: ink);

  /// Un bandeau d'une ligne à cette teinte.
  Widget notice(String message, {IconData icon = Icons.info_outline}) =>
      EteeloNotice.tinted(
        message: message,
        icon: icon,
        ink: ink,
        background: soft,
      );
}
