import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La tuile « + Nouvelle caisse », au bout de la grille. Le promoteur seul la
/// voit, et seulement tant qu'une devise n'a pas sa caisse.
class NewRegisterTile extends StatelessWidget {
  final VoidCallback onTap;

  const NewRegisterTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.treasuryNewRegister,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.surfaceRaised,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: const _HatchPainter(),
          foregroundPainter: const DashedRRectPainter(
            color: AppColors.treasuryOpeningBorder,
            borderRadius: _radius,
            strokeWidth: 2,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.brLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.treasuryNewRegisterMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: AppDimensions.treasuryNewRegisterDot / 2,
                      backgroundColor: AppColors.terreCuite,
                      child: Icon(Icons.add, color: AppColors.textOnDark),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.treasuryNewRegister,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall,
                    ),
                    Text(
                      l10n.treasuryNewRegisterHint,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppDimensions.treasuryPanelRadius),
  );
}

/// Hachures terre cuite à 3,5 % (spec C1).
class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  static const double _gap = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.terreCuite.withValues(alpha: 0.035)
      ..strokeWidth = 4;
    for (var x = -size.height; x < size.width; x += _gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}

/// La note « Bon à savoir », sur toute la largeur, sous la grille.
class GoodToKnowNote extends StatelessWidget {
  const GoodToKnowNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.treasuryNoteBg,
      borderRadius: BorderRadius.circular(AppDimensions.treasuryPanelRadius),
      border: Border.all(color: AppColors.treasuryNoteBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.terreCuite),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.treasuryGoodToKnow,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.treasuryNoteText,
            ),
          ),
        ),
      ],
    ),
  );
}
