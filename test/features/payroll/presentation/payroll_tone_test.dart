import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';

void main() {
  final tones = {
    'brouillon': PayrollTone.draft,
    'soumise': PayrollTone.submitted,
    'validée': PayrollTone.validated,
    'versée': PayrollTone.paid,
    'alerte': PayrollTone.alert,
    'mois en cours': PayrollTone.current,
  };

  for (final MapEntry(key: name, value: tone) in tones.entries) {
    test('$name : l encre se lit sur son voile et sur une carte blanche', () {
      expect(
        DashboardTones.contraste(tone.ink, tone.soft),
        greaterThanOrEqualTo(DashboardTones.seuilTexte),
      );
      expect(
        DashboardTones.contraste(tone.ink, AppColors.surfaceRaised),
        greaterThanOrEqualTo(DashboardTones.seuilTexte),
      );
    });
  }

  test('les statuts suivent les sens partagés, sauf « validée »', () {
    expect(PayrollTone.submitted.color, DashboardSense.attente);
    expect(PayrollTone.paid.color, DashboardSense.encaisse);
    expect(PayrollTone.alert.color, DashboardSense.manquant);
    // Décision du 2026-10-26 : le bleu profond propre à la Paie.
    expect(PayrollTone.validated.color, AppColors.payrollValidated);
  });
}
