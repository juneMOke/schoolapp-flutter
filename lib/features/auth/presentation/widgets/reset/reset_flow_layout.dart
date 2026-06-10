import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/auth/auth_brand_content.dart';
import 'package:school_app_flutter/core/branding/auth/auth_shell_layout.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_back_link.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_stepper_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Coquille partagée des 3 écrans du flux de réinitialisation. Équivalent de
/// [LoginPage] pour le reset : monte la charte [AuthShellLayout] avec le panneau
/// de marque éditorial dédié, le lien retour, et coiffe le formulaire de l'écran
/// par l'en-tête à stepper ([ResetStepperHeader]).
///
/// [form] ne contient donc que les champs/bandeau/bouton propres à l'étape ;
/// l'en-tête et l'espacement sont gérés ici pour éviter la répétition.
class ResetFlowLayout extends StatelessWidget {
  final int currentStep;
  final Widget form;

  const ResetFlowLayout({
    super.key,
    required this.currentStep,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthShellLayout(
      backButton: const ResetBackLink(),
      brand: AuthBrandContent(
        title: l10n.resetBrandTitle,
        condensedTitle: l10n.resetBrandTitleCondensed,
        highlight: l10n.resetBrandTitleHighlight,
        subtitle: l10n.resetBrandSubtitle,
      ),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResetStepperHeader(currentStep: currentStep),
          const SizedBox(height: 24),
          form,
        ],
      ),
    );
  }
}
