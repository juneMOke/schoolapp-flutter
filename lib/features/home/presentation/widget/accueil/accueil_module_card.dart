import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_quick_link_chip.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de présentation d'un module (spec Accueil §03).
///
/// Toute la surface est cliquable → tableau de bord du module. Au survol : la
/// carte se soulève (translateY -2), son bord se teinte et la flèche passe en
/// terre-cuite avec un léger décalage. Les puces du pied gèrent leur propre tap.
class AccueilModuleCard extends StatefulWidget {
  final AccueilModule module;

  const AccueilModuleCard({super.key, required this.module});

  @override
  State<AccueilModuleCard> createState() => _AccueilModuleCardState();
}

class _AccueilModuleCardState extends State<AccueilModuleCard> {
  bool _isHovered = false;

  void _navigateToDashboard() {
    final target = widget.module.dashboardTarget;
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
    final l10n = AppLocalizations.of(context)!;
    final module = widget.module;

    return Semantics(
      button: true,
      label: l10n.accueilModuleCardSemantics(module.title),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToDashboard,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.outCurve,
            transform: Matrix4.translationValues(
              0,
              _isHovered ? AccueilUiTokens.cardHoverLift : 0,
              0,
            ),
            padding: const EdgeInsets.all(AccueilUiTokens.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AccueilUiTokens.cardRadius),
              border: Border.all(
                color: _isHovered
                    ? AppColors.bleuArdoise.withValues(
                        alpha: AccueilUiTokens.cardBorderHoverOpacity,
                      )
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bleuProfond.withValues(
                    alpha: _isHovered
                        ? AccueilUiTokens.cardShadowHoverOpacity
                        : AccueilUiTokens.cardShadowOpacity,
                  ),
                  blurRadius: _isHovered
                      ? AccueilUiTokens.cardShadowHoverBlur
                      : AccueilUiTokens.cardShadowBlur,
                  offset: Offset(
                    0,
                    _isHovered
                        ? AccueilUiTokens.cardShadowHoverOffsetY
                        : AccueilUiTokens.cardShadowOffsetY,
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(module),
                const SizedBox(height: AccueilUiTokens.cardDescriptionGapTop),
                Expanded(
                  child: Text(
                    module.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                if (module.quickLinks.isNotEmpty) _buildFooter(module),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(AccueilModule module) {
    return Row(
      children: [
        Container(
          width: AccueilUiTokens.cardMedaillonSize,
          height: AccueilUiTokens.cardMedaillonSize,
          decoration: BoxDecoration(
            color: module.softBackground,
            borderRadius: BorderRadius.circular(
              AccueilUiTokens.cardMedaillonRadius,
            ),
          ),
          child: Icon(
            module.icon,
            size: AccueilUiTokens.cardMedaillonIconSize,
            color: module.accent,
          ),
        ),
        const SizedBox(width: AccueilUiTokens.cardTitleGap),
        Expanded(
          child: Text(
            module.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        AnimatedSlide(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          // `AnimatedSlide.offset` est exprimé en fractions de la taille de
          // l'enfant : on convertit le décalage cible (2 dp) en fraction de la
          // largeur de l'icône.
          offset: Offset(
            _isHovered
                ? AccueilUiTokens.cardArrowHoverShift /
                      AccueilUiTokens.cardArrowSize
                : 0,
            0,
          ),
          child: Icon(
            Icons.arrow_forward,
            size: AccueilUiTokens.cardArrowSize,
            color: _isHovered ? AppColors.terreCuite : AppColors.borderStrong,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AccueilModule module) {
    return Container(
      margin: const EdgeInsets.only(top: AccueilUiTokens.cardFooterGapTop),
      padding: const EdgeInsets.only(top: AccueilUiTokens.cardFooterPaddingTop),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: AccueilUiTokens.chipGap,
        runSpacing: AccueilUiTokens.chipGap,
        children: [
          for (final quickLink in module.quickLinks)
            AccueilQuickLinkChip(quickLink: quickLink),
        ],
      ),
    );
  }
}
