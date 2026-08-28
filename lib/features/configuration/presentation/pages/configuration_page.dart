import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Coquille de l'assistant de mise en service de l'école.
///
/// Route de premier niveau (`/configuration`), volontairement hors de la
/// coquille de l'application : elle doit s'ouvrir alors que l'école n'a pas
/// encore d'année académique, donc au moment précis où le menu et le tableau de
/// bord n'ont rien à afficher. La garde de route confronte
/// `school.provisioning.write` (cf. `kStandaloneRouteAccess`).
///
/// Ossature seulement à ce stade : la barre de titre, le stepper et les cinq
/// étapes arrivent avec la suite du module.
class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(child: SizedBox.expand()),
    );
  }
}
