import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// Le bandeau sombre de la Paie — livre du mois et fiche d'un agent : le
/// dégradé des registres de présence, le motif kuba, et un liseré terre
/// cuite, or et savane en pied.
class PayrollBanner extends StatelessWidget {
  final Widget child;

  const PayrollBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.brCard,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.payrollAgentBannerStart,
            AppColors.payrollAgentBannerMid,
            AppColors.payrollAgentBannerEnd,
          ],
        ),
      ),
      // Passthrough : le contenu reçoit toute la largeur du bandeau, et une
      // rangée « de part et d'autre » s'y étale.
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + AppDimensions.payrollBannerStripe,
            ),
            child: child,
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: AppDimensions.payrollBannerStripe,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.payrollBannerStripeStart,
                    AppColors.payrollBannerStripeMid,
                    AppColors.payrollBannerStripeEnd,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
