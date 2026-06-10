import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/auth/auth_brand_content.dart';
import 'package:school_app_flutter/core/branding/auth/auth_brand_panel.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Verrou éditorial à deux panneaux de la charte d'auth ETEELO CONNECT
/// (Connexion §01), partagé par la connexion et le flux de réinitialisation.
/// Pilote la bascule responsive sur la largeur du **conteneur**
/// ([LayoutBuilder]) :
/// - ≥ 900 dp : split (Row) — marque à gauche, formulaire à droite.
/// - 560–900 dp : empilé — bandeau marque + formulaire dessous.
/// - < 560 dp : empilé — bandeau slim (lockup seul) + formulaire pleine largeur.
///
/// [backButton], s'il est fourni, coiffe la colonne formulaire sur **tous** les
/// paliers (avant le contenu du form) — un seul emplacement à styliser, jamais
/// en surimpression du bandeau bleu. Null pour la connexion (entrée principale).
class AuthShellLayout extends StatelessWidget {
  final Widget form;
  final AuthBrandContent brand;
  final Widget? backButton;

  const AuthShellLayout({
    super.key,
    required this.form,
    required this.brand,
    this.backButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width >= AppBreakpoints.loginSplitMin) {
            return _SplitLayout(
              form: form,
              brand: brand,
              backButton: backButton,
              containerWidth: width,
            );
          }
          final variant = width >= AppBreakpoints.loginStackedMin
              ? BrandPanelVariant.band
              : BrandPanelVariant.slim;
          return _StackedLayout(
            form: form,
            brand: brand,
            backButton: backButton,
            variant: variant,
          );
        },
      ),
    );
  }
}

/// Assemble la colonne formulaire (bouton retour optionnel + form), partagée par
/// les deux paliers.
class _FormColumn extends StatelessWidget {
  final Widget form;
  final Widget? backButton;

  const _FormColumn({required this.form, required this.backButton});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (backButton != null) ...[
          Align(alignment: Alignment.centerLeft, child: backButton!),
          const SizedBox(height: 16),
        ],
        form,
      ],
    );
  }
}

class _SplitLayout extends StatelessWidget {
  final Widget form;
  final AuthBrandContent brand;
  final Widget? backButton;
  final double containerWidth;

  const _SplitLayout({
    required this.form,
    required this.brand,
    required this.backButton,
    required this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double formWidth =
        (containerWidth * AppDimensions.loginFormPanelRatio).clamp(
          AppDimensions.loginFormPanelMin,
          AppDimensions.loginFormPanelMax,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AuthBrandPanel(
            variant: BrandPanelVariant.split,
            content: brand,
          ),
        ),
        SizedBox(
          width: formWidth,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: _FormColumn(form: form, backButton: backButton),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedLayout extends StatelessWidget {
  final Widget form;
  final AuthBrandContent brand;
  final Widget? backButton;
  final BrandPanelVariant variant;

  const _StackedLayout({
    required this.form,
    required this.brand,
    required this.backButton,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = variant == BrandPanelVariant.slim ? 26.0 : 24.0;

    // Tout (bandeau + formulaire) dans un même défilement : au clavier, le
    // bandeau peut sortir par le haut pour libérer le formulaire (charte §01).
    // IntrinsicHeight + Expanded : le formulaire se centre verticalement dans
    // l'espace restant sous le bandeau, tout en restant défilable si l'espace
    // manque (petit écran ou clavier ouvert).
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandPanel(variant: variant, content: brand),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.loginFormStackedMax,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 28,
                            ),
                            child: _FormColumn(
                              form: form,
                              backButton: backButton,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
