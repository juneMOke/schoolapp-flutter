import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

class BiToneSectionCard extends StatelessWidget {
  static const double _headerRailWidth = 4;
  static const double _headerIconSize = 36;
  static const double _headerIconGlyphSize = 18;
  static const double _headerIconRadius = 10;
  static const double _headerIconShadowBlur = 10;
  static const double _headerIconShadowOffsetY = 4;
  static const double _headerStackMinWidth =
      AppBreakpoints.enrollmentTableGridSwitchMax / 2;

  static const List<Color> _headerGradient = [
    Color(0xFFF5F8FB),
    Color(0xFFFBF6EF),
  ];

  static const BoxDecoration _headerDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: _headerGradient,
    ),
    border: Border(bottom: BorderSide(color: AppColors.border)),
    borderRadius: BorderRadius.vertical(top: AppRadius.card),
  );

  final Widget child;
  final Widget? header;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color accentColor;
  final EdgeInsetsGeometry bodyPadding;
  final EdgeInsetsGeometry headerPadding;
  final bool showShadow;
  final Color surfaceColor;

  const BiToneSectionCard({
    super.key,
    required this.child,
    this.header,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor = AppColors.bleuArdoise,
    this.bodyPadding = const EdgeInsets.all(AppSpacing.xl - 2),
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl - 2,
      vertical: AppSpacing.lg + 2,
    ),
    this.showShadow = true,
    this.surfaceColor = AppColors.surfaceRaised,
  });

  bool get _hasStructuredHeader =>
      title != null || subtitle != null || icon != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
        boxShadow: showShadow ? AppElevation.shadowCard : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) _buildCustomHeader(header!),
          if (header == null && _hasStructuredHeader) _buildStructuredHeader(),
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(Widget content) {
    return Container(
      width: double.infinity,
      padding: headerPadding,
      decoration: _headerDecoration,
      child: content,
    );
  }

  Widget _buildStructuredHeader() {
    return Container(
      width: double.infinity,
      padding: headerPadding,
      decoration: _headerDecoration,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldStack = constraints.maxWidth < _headerStackMinWidth;

          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderLeading(),
                const SizedBox(height: AppSpacing.md),
                _buildHeaderText(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderLeading(),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildHeaderText()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderLeading() {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _headerRailWidth,
            height: _headerIconSize,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: AppRadius.brPill,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: _headerIconSize,
            height: _headerIconSize,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(_headerIconRadius),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: _headerIconShadowBlur,
                  offset: const Offset(0, _headerIconShadowOffsetY),
                ),
              ],
            ),
            child: Icon(
              icon ?? Icons.search_rounded,
              size: _headerIconGlyphSize,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Semantics(
            header: true,
            child: Text(
              title!,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        if (subtitle != null) ...[
          if (title != null) const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
