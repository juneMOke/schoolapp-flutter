import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_brand_panel.dart';

/// Verrou éditorial à deux panneaux (spec Connexion §01). Pilote la bascule
/// responsive sur la largeur du **conteneur** ([LayoutBuilder]) :
/// - ≥ 900 dp : split (Row) — marque à gauche, formulaire à droite.
/// - 560–900 dp : empilé — bandeau marque + formulaire dessous.
/// - < 560 dp : empilé — bandeau slim (lockup seul) + formulaire pleine largeur.
///
/// `resizeToAvoidBottomInset` + défilement : au focus d'un champ, le clavier
/// remonte le formulaire ; en empilé, le bandeau peut défiler hors champ.
class LoginScreenLayout extends StatelessWidget {
  final Widget form;

  const LoginScreenLayout({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width >= AppBreakpoints.loginSplitMin) {
            return _SplitLayout(form: form, containerWidth: width);
          }
          final variant = width >= AppBreakpoints.loginStackedMin
              ? LoginBrandVariant.band
              : LoginBrandVariant.slim;
          return _StackedLayout(form: form, variant: variant);
        },
      ),
    );
  }
}

class _SplitLayout extends StatelessWidget {
  final Widget form;
  final double containerWidth;

  const _SplitLayout({required this.form, required this.containerWidth});

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
        const Expanded(
          child: LoginBrandPanel(variant: LoginBrandVariant.split),
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
                child: form,
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
  final LoginBrandVariant variant;

  const _StackedLayout({required this.form, required this.variant});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = variant == LoginBrandVariant.slim ? 26.0 : 24.0;

    // Tout (bandeau + formulaire) dans un même défilement : au clavier, le
    // bandeau peut sortir par le haut pour libérer le formulaire (spec §01).
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
                  LoginBrandPanel(variant: variant),
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
                            child: form,
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
