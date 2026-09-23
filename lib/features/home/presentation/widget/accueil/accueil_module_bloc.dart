import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_module_bloc_parts.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_sub_module_pill.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pavé de présentation d'un module — variante « blocs » (spec
/// Accueil-Couleurs §05).
///
/// Le module n'est plus une carte blanche à accent discret : c'est un **aplat
/// plein** de sa couleur, portant une encre crème opaque. Les surfaces internes
/// (halo, médaillon, pastilles) ne sont jamais des couleurs nouvelles — ce sont
/// des voiles de blanc cassé posés sur le fond du module.
///
/// Zones cliquables distinctes : l'en-tête (médaillon, titre, description) mène
/// à la page d'entrée du module, chaque pastille à son propre sous-écran.
///
/// L'habillage — en-tête, médaillon, halo, anneau de focus — vit dans
/// `accueil_module_bloc_parts.dart` : ce fichier ne garde que l'état
/// d'interaction et les gestes.
class AccueilModuleBloc extends StatefulWidget {
  final AccueilModule module;

  const AccueilModuleBloc({super.key, required this.module});

  @override
  State<AccueilModuleBloc> createState() => _AccueilModuleBlocState();
}

class _AccueilModuleBlocState extends State<AccueilModuleBloc> {
  bool _isHovered = false;
  bool _isFocused = false;

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
    // §07 — le focus clavier prend l'élévation du survol, et rien d'autre : la
    // teinte du pavé ne bouge dans aucun état, sans quoi l'association
    // module → couleur se perdrait.
    final lifted = _isHovered || _isFocused;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.outCurve,
        clipBehavior: Clip.antiAlias,
        // Mouvement réduit : l'ombre de survol seule, aucune translation (§07).
        transform: Matrix4.translationValues(
          0,
          lifted && !reduceMotion ? AccueilUiTokens.blocHoverLift : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: module.tone.background,
          borderRadius: BorderRadius.circular(AccueilUiTokens.blocRadius),
          boxShadow: _shadows(lifted),
        ),
        child: Stack(
          children: [
            const AccueilModuleBlocHalo(),
            _buildContent(module),
            if (_isFocused) const AccueilModuleBlocFocusRing(),
          ],
        ),
      ),
    );
  }

  /// L'ombre reste **bleu profond** dans tous les cas, jamais la teinte du
  /// pavé : une ombre terre cuite sous un pavé terre cuite le ferait flotter
  /// dans une flaque de sa propre couleur (§05).
  List<BoxShadow> _shadows(bool lifted) => [
    BoxShadow(
      color: AppColors.bleuProfond.withValues(
        alpha: lifted
            ? AccueilUiTokens.blocShadowHoverOpacity
            : AccueilUiTokens.blocShadowOpacity,
      ),
      blurRadius: lifted
          ? AccueilUiTokens.blocShadowHoverBlur
          : AccueilUiTokens.blocShadowBlur,
      offset: Offset(
        0,
        lifted
            ? AccueilUiTokens.blocShadowHoverOffsetY
            : AccueilUiTokens.blocShadowOffsetY,
      ),
    ),
  ];

  Widget _buildContent(AccueilModule module) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AccueilUiTokens.blocPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildEntryZone(module, l10n)),
          const SizedBox(height: AccueilUiTokens.blocPillsGapTop),
          // Chaque sous-page du module est une pastille cliquable posée sur le
          // pavé (§06). Le `Wrap` les fait retomber ligne à ligne : la grille
          // reconfigure le nombre de colonnes, la largeur d'un pavé varie.
          Wrap(
            spacing: AccueilUiTokens.blocPillGap,
            runSpacing: AccueilUiTokens.blocPillGap,
            children: [
              for (final subModule in module.subModules)
                AccueilSubModulePill(
                  subModule: subModule,
                  tone: module.tone,
                  moduleTitle: module.title,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// En-tête et description : une seule cible, la page d'entrée du module.
  ///
  /// L'état « pressé » du §07 n'est pas distingué : le tap navigue aussitôt,
  /// le pavé quitte l'écran avant qu'un retour à l'ombre de repos ne soit
  /// perceptible.
  Widget _buildEntryZone(AccueilModule module, AppLocalizations l10n) {
    return Semantics(
      button: true,
      label: l10n.accueilModuleCardSemantics(module.title, module.entry.label),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _openEntryPage(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openEntryPage,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccueilModuleBlocHeaderRow(
                  module: module,
                  isHovered: _isHovered,
                  pageCountLabel: l10n.accueilModulePageCount(module.pageCount),
                ),
                const SizedBox(height: AccueilUiTokens.blocDescriptionGapTop),
                Expanded(
                  child: Text(
                    module.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AccueilUiTokens.blocDescriptionFontSize,
                      fontWeight: FontWeight.w400,
                      height: AccueilUiTokens.blocDescriptionHeight,
                      color: AppColors.accueilBlocInkBody,
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
