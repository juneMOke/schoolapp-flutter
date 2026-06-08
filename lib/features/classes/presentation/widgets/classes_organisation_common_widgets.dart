import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

class ClassesOrganisationDashedContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  const ClassesOrganisationDashedContainer({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(borderColor),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: child,
        ),
      ),
    );
  }
}

class ClassesOrganisationStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const ClassesOrganisationStatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: foreground),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(label, style: AppTextStyles.badge.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Pastille de genre : libellé (lettre + effectif) teinté — bleu = Garçons,
/// terre-cuite = Filles. Partagée par la carte « non réparti » et la carte de
/// classe.
class ClassesOrganisationGenderPill extends StatelessWidget {
  final String label;
  final Color color;

  const ClassesOrganisationGenderPill({
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

/// Marqueur de genre : carré 22 px teinté — mars (Garçon) / venus (Fille).
class ClassesOrganisationGenderMarker extends StatelessWidget {
  final ClassroomMemberGender gender;

  const ClassesOrganisationGenderMarker({required this.gender, super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (gender) {
      ClassroomMemberGender.male => (Icons.male, AppColors.bleuArdoise),
      ClassroomMemberGender.female => (Icons.female, AppColors.terreCuite),
      ClassroomMemberGender.other => (
        Icons.transgender,
        AppColors.textSecondary,
      ),
    };

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 14, color: tint),
    );
  }
}

class ClassesOrganisationInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const ClassesOrganisationInfoChip({
    required this.icon,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const borderRadius = Radius.circular(AppDimensions.cardRadius);
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect.deflate(0.5), borderRadius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()..addRRect(rRect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
