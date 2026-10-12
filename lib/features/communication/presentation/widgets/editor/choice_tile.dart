import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';

/// Un choix exclusif (catégorie, mode de ciblage) : bord de 2 dp dans sa
/// teinte une fois choisi. Lu comme un bouton radio.
class ChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final AnnouncementTone tone;
  final bool selected;
  final double minHeight;
  final VoidCallback? onTap;

  const ChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.minHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: selected,
    button: true,
    child: Material(
      color: selected ? tone.soft : AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(
          color: selected ? tone.ink : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
        ),
        hoverColor: tone.soft,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? tone.ink : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected ? tone.ink : AppColors.textPrimary,
                    ),
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
