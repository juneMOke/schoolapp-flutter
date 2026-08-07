import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne cliquable du pied d'une carte module (spec Accueil §04).
///
/// Deux traitements : la ligne « Tableau de bord » est mise en avant (médaillon
/// + fond doux + libellé gras), les autres sous-modules sont des lignes légères
/// à puce. Son `GestureDetector` absorbe le tap, donc il ne déclenche jamais la
/// navigation de la carte parente (équivalent du `stopPropagation` de la spec).
class AccueilSubModuleRow extends StatefulWidget {
  final AccueilSubModule subModule;

  /// Nom du module parent — sert uniquement au libellé d'accessibilité, pour
  /// que « Tableau de bord » ne soit pas annoncé six fois à l'identique.
  final String moduleTitle;

  const AccueilSubModuleRow({
    super.key,
    required this.subModule,
    required this.moduleTitle,
  });

  @override
  State<AccueilSubModuleRow> createState() => _AccueilSubModuleRowState();
}

class _AccueilSubModuleRowState extends State<AccueilSubModuleRow> {
  bool _isHovered = false;

  void _navigate() {
    final target = widget.subModule.target;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: target.menuId,
        subMenuId: target.subMenuId,
        title: target.title,
      ),
    );
  }

  Color get _background {
    if (_isHovered) return AppColors.bleuArdoiseSoft;
    return widget.subModule.isDashboard
        ? AppColors.surfaceAlt
        : Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subModule = widget.subModule;

    return Semantics(
      button: true,
      label: l10n.accueilSubModuleSemantics(
        widget.moduleTitle,
        subModule.label,
      ),
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
            constraints: const BoxConstraints(
              minHeight: AccueilUiTokens.subRowMinHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AccueilUiTokens.subRowPaddingH,
            ),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(AccueilUiTokens.subRowRadius),
            ),
            child: Row(
              children: [
                _Leading(isDashboard: subModule.isDashboard),
                const SizedBox(width: AccueilUiTokens.subRowLeadGap),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      subModule.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subModule.isDashboard
                          ? AppTextStyles.action.copyWith(
                              fontSize: AccueilUiTokens.subRowDashboardFontSize,
                              color: AppColors.bleuArdoise,
                            )
                          : AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                ),
                AnimatedSlide(
                  duration: AppMotion.fast,
                  curve: AppMotion.outCurve,
                  // `AnimatedSlide.offset` s'exprime en fractions de la taille
                  // de l'enfant : on convertit le décalage cible (2 dp) en
                  // fraction de la largeur du chevron.
                  offset: Offset(
                    _isHovered
                        ? AccueilUiTokens.subRowChevronHoverShift /
                              AccueilUiTokens.subRowChevronSize
                        : 0,
                    0,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: AccueilUiTokens.subRowChevronSize,
                    color: _isHovered
                        ? AppColors.bleuArdoise
                        : AppColors.borderStrong,
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

/// Repère gauche : médaillon « tendance » pour le tableau de bord, simple point
/// pour les autres pages. Les deux occupent la même largeur pour que les
/// libellés restent alignés d'une ligne à l'autre.
class _Leading extends StatelessWidget {
  final bool isDashboard;

  const _Leading({required this.isDashboard});

  @override
  Widget build(BuildContext context) {
    if (isDashboard) {
      return Container(
        width: AccueilUiTokens.subRowLeadSize,
        height: AccueilUiTokens.subRowLeadSize,
        decoration: BoxDecoration(
          color: AppColors.bleuArdoiseSoft,
          borderRadius: BorderRadius.circular(AccueilUiTokens.subRowLeadRadius),
        ),
        child: const Icon(
          Icons.trending_up,
          size: AccueilUiTokens.subRowLeadIconSize,
          color: AppColors.bleuArdoise,
        ),
      );
    }

    return SizedBox(
      width: AccueilUiTokens.subRowLeadSize,
      child: Center(
        child: Container(
          width: AccueilUiTokens.subRowDotSize,
          height: AccueilUiTokens.subRowDotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bleuArdoise.withValues(
              alpha: AccueilUiTokens.subRowDotOpacity,
            ),
          ),
        ),
      ),
    );
  }
}
