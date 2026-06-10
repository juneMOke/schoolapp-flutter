import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Lockup horizontal ETEELO CONNECT sur fond foncé : symbole coloré (arc Or
/// Doux) + wordmark « ETEELO » (blanc) / « CONNECT » (or) sur deux lignes.
///
/// Le wordmark est rendu en **texte** (et non via le SVG horizontal, dont le
/// bloc `<style>` n'est pas interprété par flutter_svg) — même choix que le
/// splash (`_SplashWordmark`), pour un rendu fiable et redimensionnable.
///
/// Décoratif : à envelopper dans un [ExcludeSemantics] par l'appelant si la
/// marque est déjà annoncée ailleurs sur l'écran.
class EteeloLockup extends StatelessWidget {
  /// Hauteur du symbole en dp ; les deux lignes du wordmark en dérivent.
  final double symbolSize;

  const EteeloLockup({super.key, this.symbolSize = 32});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primarySize = symbolSize * 0.5;
    final secondarySize = primarySize * 0.52;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        EteeloLogo(variant: EteeloLogoVariant.symbolOnDark, size: symbolSize),
        SizedBox(width: symbolSize * 0.32),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.splashBrandPrimary,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: primarySize,
                fontWeight: FontWeight.w800,
                letterSpacing: primarySize * 0.04,
                height: 1.0,
                color: AppColors.blancCasse,
              ),
            ),
            SizedBox(height: secondarySize * 0.4),
            Text(
              l10n.splashBrandSecondary,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: secondarySize,
                fontWeight: FontWeight.w600,
                letterSpacing: secondarySize * 0.34,
                height: 1.0,
                color: AppColors.orDoux,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
