import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SidebarFooter extends StatelessWidget {
  final bool isExpanded;

  const SidebarFooter({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outCurve,
      margin: EdgeInsets.fromLTRB(isExpanded ? 12 : 8, 8, isExpanded ? 12 : 8, 12),
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.textOnDark.withValues(alpha: 0.06)),
      ),
      child: Semantics(
        container: true,
        readOnly: true,
        label: l10n.homeSidebarFooterLabel,
        child: ExcludeSemantics(
          child: AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: isExpanded
                ? Row(
                    key: const ValueKey('sidebar-footer-expanded'),
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                         color: AppColors.textOnDark,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.homeSidebarFooterLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Icon(
                    key: ValueKey('sidebar-footer-collapsed'),
                    Icons.verified_outlined,
                     color: AppColors.textOnDark,
                    size: 16,
                  ),
          ),
        ),
      ),
    );
  }
}