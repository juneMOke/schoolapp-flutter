import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EteeloResultCard extends StatefulWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final Widget avatar;
  final Widget title;
  final Widget subtitle;
  final Widget statusPill;
  final List<Widget> chips;
  final String semanticLabel;

  const EteeloResultCard({
    super.key,
    required this.onTap,
    required this.accentColor,
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.statusPill,
    required this.chips,
    required this.semanticLabel,
  });

  @override
  State<EteeloResultCard> createState() => _EteeloResultCardState();
}

class _EteeloResultCardState extends State<EteeloResultCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isHovered;
    final decoration = BoxDecoration(
      color: isHighlighted
          ? widget.accentColor.withValues(alpha: 0.06)
          : AppColors.surfaceRaised,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: AppColors.border),
      boxShadow: [
        ...isHighlighted ? AppElevation.shadowRaised : AppElevation.shadowKpi,
        if (_isFocused)
          const BoxShadow(
            color: AppColors.stateFocus,
            blurRadius: 0,
            spreadRadius: 2,
          ),
      ],
    );

    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.outCurve,
          decoration: decoration,
          clipBehavior: Clip.antiAlias,
          transform: Matrix4.translationValues(
            0,
            isHighlighted ? AppDimensions.resultCardHoverTranslateY : 0,
            0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: _focusNode,
              onTap: widget.onTap,
              onHover: (value) => setState(() => _isHovered = value),
              onFocusChange: (value) => setState(() => _isFocused = value),
              borderRadius: AppRadius.brLg,
              focusColor: AppColors.stateFocus,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return widget.accentColor.withValues(alpha: 0.12);
                }
                if (states.contains(WidgetState.hovered)) {
                  return widget.accentColor.withValues(alpha: 0.04);
                }
                if (states.contains(WidgetState.focused)) {
                  return AppColors.stateFocus;
                }
                return null;
              }),
              // Stack : le contenu (non positionné) dimensionne la carte en
              // hauteur (fit contenu, pas d'espace vide), la barre d'accent est
              // positionnée pleine hauteur. Compatible avec une cellule à
              // hauteur libre (EteeloGridView en Wrap), sans IntrinsicHeight.
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppDimensions.resultCardAccentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.resultCardBodyPaddingH,
                        vertical: AppDimensions.resultCardBodyPaddingV,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              widget.avatar,
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [widget.title, widget.subtitle],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: widget.statusPill,
                          ),
                          if (widget.chips.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.gridGap),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: widget.chips,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: AppDimensions.resultCardAccentWidth,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
