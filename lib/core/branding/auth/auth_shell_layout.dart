import 'dart:math' as math;

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
    // Le formulaire se centre dans l'espace restant sous le bandeau quand la
    // place abonde, et le défilement prend le relais quand elle manque.
    //
    // ⚠️ Ce couple « remplir le reste, sinon grandir » se code avec un
    // [SliverFillRemaining] et **jamais** avec `IntrinsicHeight` + `Expanded` :
    // cette forme-là mesurait le formulaire par sa hauteur INTRINSÈQUE, que
    // `TextField` et les `Row` à enfants flexibles sous-estiment. La hauteur
    // retenue retombait alors sur le plancher `minHeight` — la hauteur offerte,
    // que le clavier venait de raboter — et l'`Expanded` imposait cette hauteur
    // trop courte au formulaire, qui débordait d'autant. Le bandeau d'erreur en
    // était la preuve : il ajoutait ses ~38 dp au débordement **sans** agrandir
    // la boîte, puisque le plancher, lui, ne dépend pas du contenu.
    // Reproduit sur téléphone en paysage et sur tablette 800×600, clavier
    // ouvert ; filet dans `auth_shell_layout_keyboard_test.dart`.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Largeur du formulaire (≤ [AppDimensions.loginFormStackedMax]) obtenue
        // par une marge SYMÉTRIQUE, et non par un `ConstrainedBox(maxWidth:)`.
        //
        // ⚠️ Le rendu est le même, la MESURE ne l'est pas :
        // `RenderConstrainedBox.computeMaxIntrinsicHeight` transmet à son enfant
        // la largeur reçue du parent sans lui appliquer son propre `maxWidth`.
        // Le formulaire était donc mesuré sur toute la largeur du viewport —
        // où ses textes ne reviennent pas à la ligne — et sa hauteur ressortait
        // trop courte. `RenderPadding`, lui, retranche bien ses marges avant de
        // mesurer : la hauteur annoncée redevient celle du rendu réel.
        // Largeur rendue à l'identique de l'ancienne forme, qui plafonnait la
        // largeur AVANT d'appliquer ses marges : plafond, puis marges.
        final formWidth = math.max(
          0.0,
          math.min(AppDimensions.loginFormStackedMax, constraints.maxWidth) -
              2 * horizontalPadding,
        );
        final sideInset = (constraints.maxWidth - formWidth) / 2;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AuthBrandPanel(variant: variant, content: brand),
            ),
            SliverFillRemaining(
              // Le formulaire n'a pas son propre défilement : il occupe au
              // moins le reste du viewport — ce qui le centre quand la place
              // abonde — et le déborde, en défilant, dès que son contenu réel
              // demande davantage. C'est ce sliver qui interroge la hauteur
              // intrinsèque ci-dessus : elle doit être exacte.
              hasScrollBody: false,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sideInset,
                      vertical: 28,
                    ),
                    child: _FormColumn(form: form, backButton: backButton),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
