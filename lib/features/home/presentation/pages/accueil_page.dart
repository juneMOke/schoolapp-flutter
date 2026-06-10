import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_brand_banner.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_modules_section.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_signature.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page d'atterrissage post-connexion (spec Accueil).
///
/// Rôle : orienter. Bandeau de marque (statique) → section modules (présentation
/// de l'application, portes d'entrée vers chaque tableau de bord) → signature.
///
/// La zone de synthèse chiffrée (KPI) est volontairement absente de cette
/// première étape (cf. spec §02, zone à états) ; elle sera ajoutée ensuite.
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modules = AccueilModulesFactory.create(l10n);

    return AppPageBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccueilBrandBanner(),
          const SizedBox(height: AccueilUiTokens.bannerToModulesGap),
          AccueilModulesSection(modules: modules),
          const SizedBox(height: AccueilUiTokens.modulesToSignatureGap),
          const AccueilSignature(),
        ],
      ),
    );
  }
}
