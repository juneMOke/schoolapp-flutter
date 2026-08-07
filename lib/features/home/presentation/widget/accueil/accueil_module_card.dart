import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_sub_module_row.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de présentation d'un module — variante « cartes » (spec Accueil §03).
///
/// Chaque carte expose **tous ses sous-modules en clair** dans son pied. Le
/// fond est légèrement teinté de la couleur du module sur les premiers 64 dp ;
/// au survol, un liseré d'accent se déploie en tête, la carte se soulève et le
/// médaillon s'anime.
///
/// Zones cliquables distinctes : l'en-tête (avec la description) mène à la page
/// d'entrée du module, chaque ligne du pied à son propre sous-écran.
class AccueilModuleCard extends StatefulWidget {
  final AccueilModule module;

  const AccueilModuleCard({super.key, required this.module});

  @override
  State<AccueilModuleCard> createState() => _AccueilModuleCardState();
}

class _AccueilModuleCardState extends State<AccueilModuleCard> {
  bool _isHovered = false;

  void _openEntryPage() {
    final target = widget.module.entry.target;
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
    final module = widget.module;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.outCurve,
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(
          0,
          _isHovered ? AccueilUiTokens.cardHoverLift : 0,
          0,
        ),
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
          boxShadow: _shadows(),
        ),
        child: Stack(
          children: [
            _TintLayer(color: module.softBackground),
            _buildContent(module),
            _AccentBar(color: module.accent, isVisible: _isHovered),
          ],
        ),
      ),
    );
  }

  /// Ombre douce au repos (portée + contact), ombre longue au survol.
  List<BoxShadow> _shadows() {
    if (_isHovered) {
      return [
        BoxShadow(
          color: AppColors.bleuProfond.withValues(
            alpha: AccueilUiTokens.cardShadowHoverOpacity,
          ),
          blurRadius: AccueilUiTokens.cardShadowHoverBlur,
          offset: const Offset(0, AccueilUiTokens.cardShadowHoverOffsetY),
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.bleuProfond.withValues(
          alpha: AccueilUiTokens.cardShadowOpacity,
        ),
        blurRadius: AccueilUiTokens.cardShadowBlur,
        offset: const Offset(0, AccueilUiTokens.cardShadowOffsetY),
      ),
      BoxShadow(
        color: AppColors.bleuProfond.withValues(
          alpha: AccueilUiTokens.cardShadowContactOpacity,
        ),
        blurRadius: AccueilUiTokens.cardShadowContactBlur,
        offset: const Offset(0, AccueilUiTokens.cardShadowContactOffsetY),
      ),
    ];
  }

  Widget _buildContent(AccueilModule module) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AccueilUiTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête + description : une seule cible, la page d'entrée.
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.accueilModuleCardSemantics(
                module.title,
                module.entry.label,
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openEntryPage,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderRow(module, l10n),
                        const SizedBox(
                          height: AccueilUiTokens.cardDescriptionGapTop,
                        ),
                        Expanded(
                          child: Text(
                            module.description,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(module),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AccueilModule module, AppLocalizations l10n) {
    return Row(
      children: [
        _Medallion(module: module, isHovered: _isHovered),
        const SizedBox(width: AccueilUiTokens.cardTitleGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuProfond,
                ),
              ),
              const SizedBox(height: AccueilUiTokens.cardSubtitleGapTop),
              Text(
                l10n.accueilModulePageCount(module.pageCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AccueilUiTokens.cardTitleGap),
        AnimatedSlide(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          // `AnimatedSlide.offset` s'exprime en fractions de la taille de
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
            color: _isHovered ? AppColors.bleuArdoise : AppColors.borderStrong,
          ),
        ),
      ],
    );
  }

  /// Pied toujours affiché (spec §03 : pas de masquage) — une ligne par page.
  Widget _buildFooter(AccueilModule module) {
    return Container(
      margin: const EdgeInsets.only(top: AccueilUiTokens.cardFooterGapTop),
      padding: const EdgeInsets.only(top: AccueilUiTokens.cardFooterPaddingTop),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < module.subModules.length; i++) ...[
            if (i > 0) const SizedBox(height: AccueilUiTokens.subRowGap),
            AccueilSubModuleRow(
              subModule: module.subModules[i],
              moduleTitle: module.title,
            ),
          ],
        ],
      ),
    );
  }
}

/// Teinte du module fondue dans la surface blanche sur les premiers 64 dp
/// (équivalent du dégradé `{soft}66 → surface-raised 64px` de la spec).
class _TintLayer extends StatelessWidget {
  final Color color;

  const _TintLayer({required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: AccueilUiTokens.cardTintHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: AccueilUiTokens.cardTintOpacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liseré d'accent en tête de carte : invisible au repos, il se déploie
/// horizontalement au survol (spec §03).
class _AccentBar extends StatelessWidget {
  final Color color;
  final bool isVisible;

  const _AccentBar({required this.color, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: AccueilUiTokens.cardAccentBarHeight,
      child: AnimatedOpacity(
        duration: AppMotion.medium,
        curve: AppMotion.outCurve,
        opacity: isVisible ? 1 : 0,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            isVisible ? 1 : AccueilUiTokens.cardAccentBarRestScaleX,
            1,
            1,
          ),
          color: color,
        ),
      ),
    );
  }
}

/// Médaillon d'icône du module : fond doux, anneau d'accent, léger effet de
/// bascule au survol de la carte.
class _Medallion extends StatelessWidget {
  final AccueilModule module;
  final bool isHovered;

  const _Medallion({required this.module, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppMotion.medium,
      curve: AppMotion.outCurve,
      scale: isHovered ? AccueilUiTokens.cardMedaillonHoverScale : 1,
      child: AnimatedRotation(
        duration: AppMotion.medium,
        curve: AppMotion.outCurve,
        turns: isHovered ? AccueilUiTokens.cardMedaillonHoverTurns : 0,
        child: Container(
          width: AccueilUiTokens.cardMedaillonSize,
          height: AccueilUiTokens.cardMedaillonSize,
          decoration: BoxDecoration(
            color: module.softBackground,
            borderRadius: BorderRadius.circular(
              AccueilUiTokens.cardMedaillonRadius,
            ),
            border: Border.all(
              color: module.accent.withValues(
                alpha: AccueilUiTokens.cardMedaillonRingOpacity,
              ),
            ),
          ),
          child: Icon(
            module.icon,
            size: AccueilUiTokens.cardMedaillonIconSize,
            color: module.accent,
          ),
        ),
      ),
    );
  }
}
