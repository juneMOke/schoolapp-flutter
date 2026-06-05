import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentJourneyAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String modeLabel;
  final String studentDisplayName;
  final int currentStep;
  final int totalSteps;

  const EnrollmentJourneyAppBar({
    super.key,
    required this.modeLabel,
    required this.studentDisplayName,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: preferredSize.height,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        _JourneyIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: l10n.previous,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                            context.go('/home');
                          },
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modeLabel.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.orDoux,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                studentDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          l10n.stepIndicator(currentStep + 1, totalSteps),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _JourneyIconButton(
                          icon: Icons.close_rounded,
                          tooltip: l10n.journeyCloseAction,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                            context.go('/home');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.orDoux.withValues(alpha: 0),
                        AppColors.orDoux.withValues(alpha: 0.65),
                        AppColors.orDoux.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _JourneyIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_JourneyIconButton> createState() => _JourneyIconButtonState();
}

class _JourneyIconButtonState extends State<_JourneyIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(
                alpha: _isHovered ? 0.18 : 0.10,
              ),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(widget.icon, size: 22, color: AppColors.textOnDark),
          ),
        ),
      ),
    );
  }
}
