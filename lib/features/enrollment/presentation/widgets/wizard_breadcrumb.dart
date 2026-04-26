import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class WizardBreadcrumb extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;

  const WizardBreadcrumb({
    super.key,
    required this.titles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.stepIndicator(
                  currentStep + 1,
                  titles.length,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: List.generate(titles.length, (index) {
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              final isFuture = index > currentStep;
              final canTap = !isFuture;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: canTap
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden,
                    child: AnimatedOpacity(
                      duration: AppMotion.fast,
                      curve: AppMotion.outCurve,
                      opacity: isFuture ? 0.55 : 1,
                      child: InkWell(
                        onTap: canTap ? () => onStepTap(index) : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : isDone
                                    ? AppTheme.primaryColor.withValues(alpha: 0.14)
                                    : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : isDone
                                          ? AppTheme.primaryColor.withValues(
                                              alpha: 0.18,
                                            )
                                          : const Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  isDone ? '✓' : '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? Colors.white
                                        : isDone
                                            ? AppTheme.primaryColor
                                            : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                titles[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? Colors.white
                                      : isDone
                                          ? AppTheme.primaryColor
                                          : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index < titles.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
