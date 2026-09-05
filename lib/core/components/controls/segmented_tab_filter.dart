import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';

/// Option générique pour [SegmentedTabFilter].
class SegmentedTabOption<T> {
  final String label;
  final T value;
  final IconData? icon;
  final String? semanticLabel;

  const SegmentedTabOption({
    required this.label,
    required this.value,
    this.icon,
    this.semanticLabel,
  });
}

class SegmentedTabFilterStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry containerPadding;
  final double? itemWidth;
  final double? itemHeight;
  final double itemBorderRadius;
  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final List<BoxShadow> selectedShadow;

  /// Hauteur imposée à la barre. `null` la laisse s'ajuster à ses onglets —
  /// obligatoire en mode enroulé, où deux rangs ne tiennent dans aucune
  /// hauteur fixée d'avance.
  final double? containerHeight;

  /// Écart entre deux onglets. Zéro par défaut : les segmentés historiques se
  /// touchent, et c'est ce qui les fait lire comme UN contrôle.
  final double itemGap;

  /// Rembourrage intérieur d'un onglet.
  final EdgeInsetsGeometry itemPadding;

  /// Écart entre l'icône et le libellé d'un onglet.
  final double itemContentGap;

  const SegmentedTabFilterStyle({
    this.backgroundColor = AppColors.surfaceAlt,
    this.borderColor = AppColors.border,
    this.borderRadius = AppDimensions.enrollmentStatsChartRadius,
    this.containerPadding = const EdgeInsets.all(3),
    this.itemWidth,
    this.itemHeight,
    this.itemBorderRadius = 9,
    this.selectedBackgroundColor = AppColors.enrollmentStatsAccent,
    this.selectedForegroundColor = Colors.white,
    this.unselectedForegroundColor = AppColors.textSecondary,
    this.selectedShadow = const [
      BoxShadow(color: Color(0x2E1B4D6B), blurRadius: 4, offset: Offset(0, 2)),
    ],
    this.containerHeight = AppDimensions.enrollmentStatsPeriodFilterHeight,
    this.itemGap = 0,
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingXS,
    ),
    this.itemContentGap = AppSpacing.xs,
  });

  static const kpi = SegmentedTabFilterStyle(
    selectedShadow: AppElevation.shadowKpi,
  );

  /// Fenêtre de temps d'un tableau de bord — **onglets pleins**.
  ///
  /// Plus hauts (44 dp, une vraie cible tactile), plus espacés et plus arrondis
  /// que le segmenté de filtre : « le choix de la période est l'action la plus
  /// fréquente de l'écran, il ne doit jamais être confondu avec un filtre
  /// secondaire ». Sans hauteur imposée, pour s'enrouler sur deux rangs quand
  /// cinq onglets ne tiennent plus sur une ligne.
  static const window = SegmentedTabFilterStyle(
    borderRadius: AppDimensions.enrollmentDashboardTabsRadius,
    containerPadding: EdgeInsets.all(
      AppDimensions.enrollmentDashboardTabsPadding,
    ),
    containerHeight: null,
    itemHeight: AppDimensions.enrollmentDashboardTabMinHeight,
    itemBorderRadius: AppDimensions.enrollmentDashboardTabRadius,
    itemGap: AppDimensions.enrollmentDashboardTabGap,
    itemPadding: EdgeInsets.symmetric(
      horizontal: AppDimensions.enrollmentDashboardTabPaddingH,
    ),
    itemContentGap: AppSpacing.sm,
    selectedBackgroundColor: AppColors.bleuArdoise,
  );
}

/// Filtre à onglets segmentés générique.
///
/// Utilisation :
/// ```dart
/// SegmentedTabFilter<EnrollmentStatsPeriod>(
///   options: [...],
///   selected: state.selectedPeriod,
///   onSelected: (p) => context.read<EnrollmentStatsBloc>().add(...),
/// )
/// ```
class SegmentedTabFilter<T> extends StatelessWidget {
  final List<SegmentedTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? semanticsLabel;
  final SegmentedTabFilterStyle style;

  /// Si `true`, les onglets se partagent équitablement la largeur disponible
  /// (`Expanded`) — à utiliser dans un conteneur de largeur bornée et étroit
  /// (ex. modale) pour éviter tout débordement. Par défaut `false` : largeur
  /// intrinsèque (comportement des filtres de période des dashboards).
  final bool expand;

  /// Faux pendant qu'une action déclenchée par l'onglet actif est en vol :
  /// le contrôle se grise et n'accepte plus de tap.
  final bool enabled;

  /// Si `true`, les onglets s'enroulent sur plusieurs rangs quand la largeur
  /// ne suffit plus, au lieu de se comprimer sur une ligne.
  ///
  /// À réserver aux barres de **navigation** — une fenêtre de temps, dont
  /// chaque onglet doit garder sa cible tactile de 44 dp. Un filtre secondaire
  /// à trois options n'en a pas besoin et reste sur une ligne, où il se lit
  /// comme un seul contrôle.
  ///
  /// Incompatible avec [expand], qui répartit la largeur sur **une** ligne : le
  /// mode enroulé donne à chaque onglet sa largeur intrinsèque.
  final bool wrap;

  const SegmentedTabFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.semanticsLabel,
    this.style = const SegmentedTabFilterStyle(),
    this.expand = false,
    this.enabled = true,
    this.wrap = false,
  }) : assert(
         !(wrap && expand),
         'SegmentedTabFilter : `wrap` et `expand` s\'excluent — le premier '
         'donne aux onglets leur largeur intrinsèque sur plusieurs rangs, le '
         'second les étire à parts égales sur une seule ligne.',
       );

  /// Opacité du contrôle grisé.
  static const double _disabledOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      // Grisé : on n'enveloppe QUE dans ce cas, pour que l'arbre du cas normal
      // reste exactement celui d'avant.
      child: enabled
          ? _buildBar()
          : Opacity(
              opacity: _disabledOpacity,
              child: IgnorePointer(child: _buildBar()),
            ),
    );
  }

  Widget _buildBar() {
    return Container(
      // Une hauteur imposée empêche tout enroulement : deux rangs ne tiennent
      // dans aucune hauteur fixée d'avance. Le style l'annule (`null`) pour les
      // barres enroulables.
      height: wrap ? null : style.containerHeight,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(color: style.borderColor),
      ),
      padding: style.containerPadding,
      child: wrap ? _buildWrappedTabs() : _buildRowTabs(),
    );
  }

  /// Les onglets sur une ligne — le rendu historique.
  Widget _buildRowTabs() {
    final tabs = <Widget>[];
    for (final opt in options) {
      if (tabs.isNotEmpty && style.itemGap > 0) {
        tabs.add(SizedBox(width: style.itemGap));
      }
      tabs.add(expand ? Expanded(child: _buildTab(opt)) : _buildTab(opt));
    }
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: tabs,
    );
  }

  /// Les onglets sur autant de rangs qu'il en faut, chacun à sa hauteur pleine.
  Widget _buildWrappedTabs() {
    return Wrap(
      spacing: style.itemGap,
      runSpacing: style.itemGap,
      children: [for (final opt in options) _buildTab(opt)],
    );
  }

  Widget _buildTab(SegmentedTabOption<T> opt) {
    final isSelected = opt.value == selected;
    final semanticLabel = opt.semanticLabel ?? opt.label;
    final isIconOnly = opt.icon != null && opt.label.isEmpty;
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      onTap: () => onSelected(opt.value),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(style.itemBorderRadius),
            onTap: () => onSelected(opt.value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.outCurve,
              width: style.itemWidth,
              height: style.itemHeight,
              alignment: Alignment.center,
              padding: isIconOnly ? EdgeInsets.zero : style.itemPadding,
              decoration: isSelected
                  ? BoxDecoration(
                      color: style.selectedBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        style.itemBorderRadius,
                      ),
                      boxShadow: style.selectedShadow,
                    )
                  : const BoxDecoration(),
              child: _buildTabContent(opt, isSelected),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(SegmentedTabOption<T> opt, bool isSelected) {
    final color = isSelected
        ? style.selectedForegroundColor
        : style.unselectedForegroundColor;
    final textStyle = AppTextStyles.caption.copyWith(
      color: color,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );

    if (opt.icon != null && opt.label.isEmpty) {
      return Icon(opt.icon, size: 18, color: color);
    }

    if (opt.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(opt.icon, size: 16, color: color),
          SizedBox(width: style.itemContentGap),
          Flexible(
            child: Text(
              opt.label,
              style: textStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      opt.label,
      style: textStyle,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
