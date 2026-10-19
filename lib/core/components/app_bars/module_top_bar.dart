import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/components/app_bars/dark_bar_parts.dart';

/// La barre du haut d'un écran de module qui porte sa propre barre — elle
/// **ne défile pas**.
///
/// Même anatomie que la barre des dossiers élève : Bleu Profond texturé Kuba,
/// sur-titre or-doux, liseré or sous la barre. Un écran ouvert HORS de la
/// coquille n'a ni barre latérale ni TopBar : sans elle, il se lirait comme un
/// autre logiciel, et rien ne dirait comment en revenir.
///
/// Née pour la caisse boutique, où elle remplace aussi le fil d'Ariane et porte
/// le panier à droite ; tout écran qui s'ouvre hors de la coquille la reprend.
///
/// Posée en `appBar` du `Scaffold` — c'est ce qui la maintient hors du
/// défilement, que `AppPageBackground` confine à son corps.
class ModuleTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String eyebrow;
  final String title;

  /// Posé à droite, hors du défilement. `null` sur les écrans qui n'ont rien à
  /// y porter.
  final Widget? action;

  /// `null` sur la page d'entrée d'un module : elle n'a nulle part où revenir.
  final VoidCallback? onBack;
  final String? backTooltip;

  const ModuleTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
    this.onBack,
    this.backTooltip,
  });

  static const double _dividerHeight = 2;
  static const double _backSize = 42;

  /// Liseré qui s'éteint vers la droite — la même séparation que sur les
  /// dossiers, sans leur halo centré.
  static final List<Color> _dividerColors = [
    AppColors.orDoux.withValues(alpha: 0.55),
    AppColors.orDoux.withValues(alpha: 0.15),
  ];

  /// Hauteur de la barre, liseré compris — pour la barre qui l'enveloppe.
  static const Size barSize = Size.fromHeight(
    AppDimensions.topBarHeight + _dividerHeight,
  );

  @override
  Size get preferredSize => barSize;

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
      flexibleSpace: const KubaTopBarBackground(),
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spacingM),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DarkBarIconButton(
                  size: _backSize,
                  icon: Icons.arrow_back_rounded,
                  iconSize: 22,
                  baseColor: AppColors.textOnDark.withValues(alpha: 0.10),
                  borderRadius: AppRadius.brMd,
                  tooltip: backTooltip,
                  onTap: onBack!,
                ),
              ),
            ),
      title: DarkBarHeading(eyebrow: eyebrow, title: title),
      actions: [
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingM),
            child: Center(child: action),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_dividerHeight),
        child: GoldDivider(height: _dividerHeight, colors: _dividerColors),
      ),
    );
  }
}
