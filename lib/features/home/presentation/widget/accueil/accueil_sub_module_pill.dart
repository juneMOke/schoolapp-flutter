import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module_tone.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pastille de sous-menu posée sur un pavé module (spec Accueil-Couleurs §06).
///
/// Deux rangs seulement : la pastille **Tableau de bord**, accentuée — voile
/// plus dense, bord en couleur d'accent, libellé crème en demi-gras — et les
/// pastilles ordinaires, en voile léger et encre principale.
///
/// L'accent du module colore le **bord**, jamais le libellé : l'or ne dépasse
/// pas 2,6:1 sur ces fonds (§04). Un bord n'est pas du texte, il échappe au
/// seuil ; un libellé, non.
class AccueilSubModulePill extends StatefulWidget {
  final AccueilSubModule subModule;

  /// Teinte du pavé porteur — seule source de la couleur d'accent du bord.
  final AccueilModuleTone tone;

  /// Nom du module parent — sert uniquement au libellé d'accessibilité, pour
  /// que « Tableau de bord » ne soit pas annoncé huit fois à l'identique.
  final String moduleTitle;

  const AccueilSubModulePill({
    super.key,
    required this.subModule,
    required this.tone,
    required this.moduleTitle,
  });

  @override
  State<AccueilSubModulePill> createState() => _AccueilSubModulePillState();
}

class _AccueilSubModulePillState extends State<AccueilSubModulePill> {
  bool _isHovered = false;
  bool _isFocused = false;

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

  /// Voile de fond. Le survol éclaircit les deux rangs de la même valeur — et
  /// cette valeur est plafonnée : un voile clair fait BAISSER le contraste du
  /// libellé posé dessus (cf. `blocPillHoverVeil`).
  double get _veil {
    if (_isHovered || _isFocused) return AccueilUiTokens.blocPillHoverVeil;
    return widget.subModule.isDashboard
        ? AccueilUiTokens.blocPillDashboardVeil
        : AccueilUiTokens.blocPillVeil;
  }

  /// Le bord porte l'accent du module sur la pastille « Tableau de bord », et
  /// prend l'accent sur n'importe quelle pastille au focus clavier : c'est le
  /// seul signal de focus qui ne touche pas au libellé.
  Color get _borderColor {
    if (widget.subModule.isDashboard || _isFocused) return widget.tone.accent;
    return AppColors.accueilBlocInkMain.withValues(
      alpha: AccueilUiTokens.blocPillBorderVeil,
    );
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
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _isHovered = value),
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _navigate(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigate,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.outCurve,
            constraints: const BoxConstraints(
              minHeight: AccueilUiTokens.blocPillMinHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AccueilUiTokens.blocPillPaddingH,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accueilBlocInkMain.withValues(alpha: _veil),
              borderRadius: AppRadius.brPill,
              border: Border.all(color: _borderColor),
            ),
            child: ExcludeSemantics(
              child: Text(
                subModule.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AccueilUiTokens.blocPillFontSize,
                  fontWeight: subModule.isDashboard
                      ? FontWeight.w600
                      : FontWeight.w500,
                  // Crème pour le tableau de bord sur TOUS les pavés, encre
                  // principale pour les autres — jamais l'accent (§03).
                  color: subModule.isDashboard
                      ? AppColors.accueilBlocAccentCreme
                      : AppColors.accueilBlocInkMain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
