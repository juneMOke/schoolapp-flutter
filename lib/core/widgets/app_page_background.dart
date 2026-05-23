import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Fond visuel standard partagé par toutes les pages de l'application
/// (gradient doux + orbes décoratifs + zone centrée scrollable).
class AppPageBackground extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;

  const AppPageBackground({
    super.key,
    required this.child,
    this.scrollable = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
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
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.pageBackgroundGradientStart,
              AppColors.pageBackgroundGradientMiddle,
              AppColors.pageBackgroundGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            const _AppDecorativeOrbs(),
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

class _AppDecorativeOrbs extends StatelessWidget {
  const _AppDecorativeOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: AppDimensions.pageBackgroundOrbLargeTop,
          right: AppDimensions.pageBackgroundOrbLargeRight,
          child: Container(
            width: AppDimensions.pageBackgroundOrbLargeSize,
            height: AppDimensions.pageBackgroundOrbLargeSize,
            decoration: BoxDecoration(
              color: AppColors.pageBackgroundAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: AppDimensions.pageBackgroundOrbMediumTop,
          left: AppDimensions.pageBackgroundOrbMediumLeft,
          child: Container(
            width: AppDimensions.pageBackgroundOrbMediumSize,
            height: AppDimensions.pageBackgroundOrbMediumSize,
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
