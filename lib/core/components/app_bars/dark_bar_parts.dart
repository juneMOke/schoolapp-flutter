import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// Pièces communes des barres sombres hors coquille ([StudentDetailAppBar],
/// [ModuleTopBar]) : la TopBar applicative reprise telle quelle, pour que
/// l'écran n'ait pas l'air d'un autre logiciel.

/// Fond de la barre : dégradé Bleu Profond → Bleu Ardoise + filigrane Kuba.
class KubaTopBarBackground extends StatelessWidget {
  const KubaTopBarBackground({super.key});

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

/// Liseré or-doux sous la barre, en dégradé horizontal de [colors].
class GoldDivider extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const GoldDivider({super.key, required this.height, required this.colors});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
  );
}

/// Sur-titre or-doux en capitales et titre, chacun sur une ligne.
class DarkBarHeading extends StatelessWidget {
  final String eyebrow;
  final String title;

  const DarkBarHeading({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: AppTypography.titleLarge.copyWith(color: AppColors.textOnDark),
        ),
      ],
    );
  }
}

/// Bouton carré (retour, fermer) sur fond blanc translucide.
class DarkBarIconButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final Color baseColor;
  final Color? hoverColor;
  final BorderRadius borderRadius;

  /// Une icône seule ne dit rien à la souris ni au lecteur d'écran : tout
  /// appelant qui le peut la nomme.
  final String? tooltip;
  final VoidCallback onTap;

  const DarkBarIconButton({
    super.key,
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.baseColor,
    required this.tooltip,
    required this.onTap,
    this.hoverColor,
    this.borderRadius = AppRadius.brSm,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: baseColor,
        borderRadius: borderRadius,
        child: InkWell(
          focusColor: AppColors.stateFocusOnDark,
          hoverColor: hoverColor,
          borderRadius: borderRadius,
          onTap: onTap,
          child: Icon(icon, size: iconSize, color: AppColors.textOnDark),
        ),
      ),
    );
    final message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}
