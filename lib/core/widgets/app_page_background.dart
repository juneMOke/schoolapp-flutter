import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/core/widgets/page_background_halos.dart';

enum AppPageBackgroundStyle { decorated, flat }

/// Fond visuel standard partagé par toutes les pages de l'application
/// (gradient doux + orbes décoratifs + zone centrée scrollable).
class AppPageBackground extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final AppPageBackgroundStyle style;
  final Color flatBackgroundColor;

  const AppPageBackground({
    super.key,
    required this.child,
    this.scrollable = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.style = AppPageBackgroundStyle.decorated,
    this.flatBackgroundColor = AppColors.surface,
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

    final body = style == AppPageBackgroundStyle.flat
        ? DecoratedBox(
            decoration: BoxDecoration(color: flatBackgroundColor),
            child: _buildScrollableContent(context, content),
          )
        : DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.pageBackgroundGradientStart,
                  AppColors.pageBackgroundGradientEnd,
                ],
              ),
            ),
            child: Stack(
              children: [
                const PageBackgroundHalos(),
                const KubaPatternLayer(),
                _buildScrollableContent(context, content),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }

  Widget _buildScrollableContent(BuildContext context, Widget content) {
    if (scrollable) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding(context),
          vertical: AppDimensions.spacingL,
        ),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(context),
        vertical: AppDimensions.spacingL,
      ),
      child: content,
    );
  }
}
