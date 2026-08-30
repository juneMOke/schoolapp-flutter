import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// La barre du haut des écrans de la caisse — elle **ne défile pas**.
///
/// Même anatomie que la barre des dossiers élève : Bleu Profond texturé Kuba,
/// sur-titre or-doux, liseré or sous la barre. La caisse n'est pas un écran à
/// part de l'application, et une barre claire l'aurait fait lire comme tel.
///
/// Elle remplace le fil d'Ariane « Accueil / Finances / Boutique », qui coûtait
/// une ligne pour ne dire que d'où l'on venait. Ce qui doit rester sous les yeux
/// d'un guichet, c'est le panier : au sommet, à droite, quelle que soit la
/// position du catalogue.
///
/// Posée en `appBar` du `Scaffold` — c'est ce qui la maintient hors du
/// défilement, que `AppPageBackground` confine à son corps.
class BoutiqueTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String eyebrow;
  final String title;

  /// Posé à droite, hors du défilement. `null` sur les écrans qui n'ont pas de
  /// panier à porter.
  final Widget? action;

  /// `null` sur la page d'entrée du module : elle n'a nulle part où revenir.
  final VoidCallback? onBack;
  final String? backTooltip;

  const BoutiqueTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
    this.onBack,
    this.backTooltip,
  });

  static const double _dividerHeight = 2;
  static const double _backSize = 42;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDimensions.topBarHeight + _dividerHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppDimensions.topBarHeight,
      titleSpacing: onBack == null ? AppDimensions.spacingM : 0,
      leadingWidth: AppDimensions.spacingM + _backSize + AppDimensions.spacingS,
      flexibleSpace: const _KubaTopBarBackground(),
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spacingM),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SquareIconButton(
                  size: _backSize,
                  icon: Icons.arrow_back_rounded,
                  tooltip: backTooltip,
                  onTap: onBack!,
                ),
              ),
            ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.orDoux,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
      actions: [
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingM),
            child: Center(child: action),
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_dividerHeight),
        child: _GoldDivider(height: _dividerHeight),
      ),
    );
  }
}

/// Bleu Profond → Bleu Ardoise, texturé Kuba : la TopBar applicative, reprise
/// telle quelle pour que la caisse n'ait pas l'air d'un autre logiciel.
class _KubaTopBarBackground extends StatelessWidget {
  const _KubaTopBarBackground();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
      ),
    ),
    child: Stack(fit: StackFit.expand, children: [KubaPatternLayer()]),
  );
}

/// Liseré or-doux sous la barre — la même séparation que sur les dossiers.
class _GoldDivider extends StatelessWidget {
  final double height;

  const _GoldDivider({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.orDoux.withValues(alpha: 0.55),
          AppColors.orDoux.withValues(alpha: 0.15),
        ],
      ),
    ),
  );
}

class _SquareIconButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.textOnDark.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: AppColors.textOnDark,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
