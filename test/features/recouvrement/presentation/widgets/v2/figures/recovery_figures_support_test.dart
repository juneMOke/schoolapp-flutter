import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_figures_support.dart';

void main() {
  test('encre du taux : seuils pris dans AppConstants', () {
    const healthy = AppConstants.recoveryRateHealthyFromPercent;
    const watch = AppConstants.recoveryRateWatchFromPercent;
    final green = DashboardTones.encreLisible(DashboardSense.encaisse);
    final red = DashboardTones.encreLisible(DashboardSense.manquant);
    expect(RecoveryFiguresSupport.rateInk(null), AppColors.textMutedAa);
    expect(RecoveryFiguresSupport.rateInk(healthy), green);
    expect(RecoveryFiguresSupport.rateInk(healthy - 1), AppColors.ambreInk);
    expect(RecoveryFiguresSupport.rateInk(watch), AppColors.ambreInk);
    expect(RecoveryFiguresSupport.rateInk(watch - 1), red);
  });
}
