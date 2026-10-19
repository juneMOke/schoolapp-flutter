import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/content_max_width.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_breadcrumb.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_full_bleed_screens.dart';

/// Cadre de l'écran affiché : rien pour un écran plein cadre, sinon fil
/// d'Ariane, marges et colonne centrée.
class ShellContentFrame extends StatelessWidget {
  final NavigationState state;

  /// Marges de 16 dp (tiroir) au lieu de 24, et pleine largeur.
  final bool isCompact;
  final Widget child;

  const ShellContentFrame({
    super.key,
    required this.state,
    required this.isCompact,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Pages plein-cadre (sans fil d'Ariane) : elles peignent déjà leur propre
    // fond Kuba et gèrent padding + centrage via AppPageBackground. On leur
    // donne TOUT le volet pour que le fond couvre l'intégralité de la page
    // (gouttières et marges comprises), au lieu de le confiner dans une boîte
    // paddée/centrée par la coquille (ce qui évite aussi un double padding).
    if (shellFullBleedSubMenuIds.contains(state.selectedSubMenuId)) {
      return child;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShellBreadcrumb(state: state),
        const SizedBox(height: AppDimensions.spacingL),
        Expanded(child: child),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(
        isCompact ? AppDimensions.spacingM : AppDimensions.spacingL,
      ),
      // Bureau : contenu plafonné à 1180 dp et centré ; compact : pleine largeur.
      child: isCompact ? content : ContentMaxWidth(child: content),
    );
  }
}
