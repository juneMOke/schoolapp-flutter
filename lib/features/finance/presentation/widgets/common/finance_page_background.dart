import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Fond visuel standard des pages Finance (gradient + orbes + zone centree).
class FinancePageBackground extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const FinancePageBackground({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 420) {
      return AppDimensions.spacingM;
    }
    return AppDimensions.spacingL;
  }

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.detailContentMaxWidth,
        ),
        child: child,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.financeDetailGradientStart,
              AppColors.financeDetailGradientMiddle,
              AppColors.financeDetailGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            const _FinanceDecorativeOrbs(),
            if (scrollable)
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding(context),
                  vertical: AppDimensions.spacingL,
                ),
                child: content,
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding(context),
                  vertical: AppDimensions.spacingL,
                ),
                child: content,
              ),
          ],
        ),
      ),
    );
  }
}

class _FinanceDecorativeOrbs extends StatelessWidget {
  const _FinanceDecorativeOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: AppDimensions.financeDetailOrbLargeTop,
          right: AppDimensions.financeDetailOrbLargeRight,
          child: Container(
            width: AppDimensions.financeDetailOrbLargeSize,
            height: AppDimensions.financeDetailOrbLargeSize,
            decoration: BoxDecoration(
              color: AppColors.financeDetailAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: AppDimensions.financeDetailOrbMediumTop,
          left: AppDimensions.financeDetailOrbMediumLeft,
          child: Container(
            width: AppDimensions.financeDetailOrbMediumSize,
            height: AppDimensions.financeDetailOrbMediumSize,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
