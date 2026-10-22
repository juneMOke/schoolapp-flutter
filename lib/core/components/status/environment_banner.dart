import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Badge d'angle « DEV » / « STG » posé au-dessus de toutes les routes : sur
/// une tablette qui porte plusieurs installations, il dit sur quelle base on
/// écrit avant le moindre geste.
///
/// Mêmes libellé et couleur que le bandeau de l'icône de lancement du flavor
/// (`scripts/generate_flavor_icons.py`). Coin haut de fin, comme le bandeau
/// de debug de Flutter : purement peint, il laisse passer les touchers vers
/// les actions de la barre qu'il chevauche.
///
/// Affiché selon [EnvConfig.showEnvironmentBanner] — hors prod par défaut.
class EnvironmentBanner extends StatelessWidget {
  final EnvConfig config;
  final Widget child;

  const EnvironmentBanner({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.showEnvironmentBanner) return child;
    final l10n = AppLocalizations.of(context)!;
    final (message, color) = switch (config.environment) {
      AppEnvironment.dev => (l10n.environmentBadgeDev, AppColors.vertSavane),
      AppEnvironment.staging => (
        l10n.environmentBadgeStaging,
        AppColors.terreCuiteDark,
      ),
      AppEnvironment.prod => (l10n.environmentBadgeProd, AppColors.bleuProfond),
    };
    return Banner(
      message: message,
      location: BannerLocation.topEnd,
      color: color,
      child: child,
    );
  }
}
