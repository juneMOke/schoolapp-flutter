import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un bloc de formulaire : médaillon et filet à la couleur de l'étape, titre,
/// sous-titre, puis les champs.
class StaffFormBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const StaffFormBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
    this.subtitle,
  });

  static const double _stripeWidth = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      // Le filet se pose en `Positioned` : un `IntrinsicHeight` le calerait
      // sur la hauteur du bloc, mais les rangées de champs mesurent leur
      // largeur (`LayoutBuilder`), ce qu'une mesure intrinsèque interdit.
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg + _stripeWidth,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Heading(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  color: color,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...children,
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _stripeWidth,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _Heading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleSmall),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Une rangée de champs qui passe à la ligne quand la place manque, chaque
/// champ gardant une largeur lisible.
class StaffFieldRow extends StatelessWidget {
  final List<Widget> children;

  const StaffFieldRow({super.key, required this.children});

  static const double _minFieldWidth = 220;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minFieldWidth).floor().clamp(
          1,
          children.length,
        );
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    ),
  );
}
