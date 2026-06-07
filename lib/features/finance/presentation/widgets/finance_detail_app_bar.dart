import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// AppBar claire des sous-détails facturation (détail d'un frais / d'un
/// paiement). La page de facturation, elle, utilise [FacturationDetailAppBar].
class FinanceDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String fallbackRoute;
  final IconData icon;

  const FinanceDetailAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fallbackRoute,
    this.icon = Icons.receipt_long_outlined,
  });

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute);
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      toolbarHeight: AppDimensions.topBarHeight,
      titleSpacing: AppDimensions.spacingS,
      leadingWidth: AppDimensions.spacingXL + AppDimensions.spacingL,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spacingM),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton.filledTonal(
            onPressed: () => _goBack(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.bleuArdoise.withValues(alpha: 0.10),
              foregroundColor: AppColors.bleuArdoise,
              minimumSize: const Size(36, 36),
              maximumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: AppDimensions.spacingXL + AppDimensions.spacingXS,
            height: AppDimensions.spacingXL + AppDimensions.spacingXS,
            decoration: BoxDecoration(
              color: AppColors.bleuArdoise.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
            child: Icon(icon, color: AppColors.bleuArdoise, size: 20),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.totalAmountLora.copyWith(
                    fontSize: 20,
                    color: AppColors.bleuArdoise,
                  ),
                ),
                if (subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}
