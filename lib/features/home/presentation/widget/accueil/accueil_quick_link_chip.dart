import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Puce de lien rapide dans le pied d'une carte module (spec Accueil §04).
///
/// Raccourci secondaire menant directement à un sous-écran. Son `InkWell`
/// intercepte le tap (les `InkWell` imbriqués absorbent le geste), donc il ne
/// déclenche jamais la navigation de la carte parente (équivalent du
/// `stopPropagation` de la spec).
class AccueilQuickLinkChip extends StatefulWidget {
  final AccueilQuickLink quickLink;

  const AccueilQuickLinkChip({super.key, required this.quickLink});

  @override
  State<AccueilQuickLinkChip> createState() => _AccueilQuickLinkChipState();
}

class _AccueilQuickLinkChipState extends State<AccueilQuickLinkChip> {
  bool _isHovered = false;

  void _navigate() {
    final target = widget.quickLink.target;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: target.menuId,
        subMenuId: target.subMenuId,
        title: target.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.quickLink.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigate,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.outCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: AccueilUiTokens.chipPaddingH,
              vertical: AccueilUiTokens.chipPaddingV,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.bleuArdoise.withValues(
                      alpha: AccueilUiTokens.chipHoverOpacity,
                    )
                  : AppColors.surfaceAlt,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.quickLink.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.bleuArdoise,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AccueilUiTokens.chipIconGap),
                const Icon(
                  Icons.chevron_right,
                  size: AccueilUiTokens.chipIconSize,
                  color: AppColors.bleuArdoise,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
