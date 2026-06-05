import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Carte d'etat vide reutilisable qui occupe toute la zone de resultats
/// tout en gardant une carte centree et lisible.
class EteeloEmptyResult extends StatelessWidget {
  final String label;
  final String? description;
  final List<Widget> criteriaChips;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final List<Widget> actions;
  final IconData medallionIcon;
  final IconData? cornerBadgeIcon;
  final Color accentColor;
  final double maxWidth;
  final double minHeight;
  final EdgeInsetsGeometry cardPadding;
  final String? semanticsLabel;
  final bool autofocusPrimaryAction;
  final bool fullWidthCard;

  const EteeloEmptyResult({
    super.key,
    required this.label,
    this.description,
    this.criteriaChips = const <Widget>[],
    this.primaryAction,
    this.secondaryAction,
    this.actions = const <Widget>[],
    this.medallionIcon = Icons.search_rounded,
    this.cornerBadgeIcon,
    this.accentColor = AppColors.bleuArdoise,
    this.maxWidth = 460,
    this.minHeight = 380,
    this.cardPadding = const EdgeInsets.fromLTRB(32, 52, 32, 44),
    this.semanticsLabel,
    this.autofocusPrimaryAction = false,
    this.fullWidthCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryAction;
    final effectiveActions = actions.isNotEmpty
        ? actions
        : <Widget?>[
            secondaryAction,
            if (primary != null)
              autofocusPrimaryAction
                  ? Focus(autofocus: true, child: primary)
                  : primary,
          ].whereType<Widget>().toList(growable: false);

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel ?? label,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Center(child: _buildCard(effectiveActions)),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> effectiveActions) {
    final content = Container(
      width: fullWidthCard ? double.infinity : null,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Medallion(
            icon: medallionIcon,
            cornerBadgeIcon: cornerBadgeIcon,
            accentColor: accentColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (description != null && description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (criteriaChips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: criteriaChips,
            ),
          ],
          if (effectiveActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: effectiveActions,
            ),
          ],
        ],
      ),
    );

    if (fullWidthCard) {
      return content;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
  }
}

class _Medallion extends StatelessWidget {
  final IconData icon;
  final IconData? cornerBadgeIcon;
  final Color accentColor;

  const _Medallion({
    required this.icon,
    required this.cornerBadgeIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: const _DashedCirclePainter(
              color: AppColors.borderStrong,
              strokeWidth: 2,
              dashLength: 6,
              dashGap: 4,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFEBF2F7), AppColors.surfaceAlt],
                ),
              ),
              child: Icon(icon, size: 38, color: AppColors.bleuArdoise),
            ),
          ),
          if (cornerBadgeIcon != null)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  border: Border.all(color: AppColors.surfaceRaised, width: 3),
                ),
                child: Icon(
                  cornerBadgeIcon,
                  size: 14,
                  color: AppColors.surfaceRaised,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.141592653589793 * radius;
    final patternLength = dashLength + dashGap;
    final dashCount = (circumference / patternLength).floor();

    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i * patternLength) / radius;
      final sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}
