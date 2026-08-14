import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/core/widgets/page_background_halos.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_chrome_density.dart';

/// Fond du parcours d'inscription (stepper) : même décor que les autres pages
/// — dégradé doux + halos elliptiques + filigrane Kuba — derrière le contenu.
class EnrollmentDetailContentShell extends StatelessWidget {
  final Widget child;

  const EnrollmentDetailContentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.surfaceCool],
        ),
      ),
      child: Stack(
        children: [
          const PageBackgroundHalos(),
          const KubaPatternLayer(),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth <= AppBreakpoints.detailCompactMax;
              // Barre/pied à pleine largeur : seule une marge basse subsiste.
              // Clavier ouvert, ces 24 dp pèsent un cinquième de la hauteur qui
              // reste au parcours : ils s'effacent avec le reste du chrome.
              final density = WizardChromeDensity.forHeight(
                constraints.maxHeight,
              );
              final shellPadding = !density.usesFullSpacing
                  ? EdgeInsets.zero
                  : isCompact
                  ? const EdgeInsets.only(bottom: AppSpacing.md)
                  : const EdgeInsets.only(bottom: AppSpacing.xl);

              return Padding(padding: shellPadding, child: child);
            },
          ),
        ],
      ),
    );
  }
}
