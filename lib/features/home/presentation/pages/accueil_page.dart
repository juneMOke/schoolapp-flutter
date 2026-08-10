import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
// Import debug — uniquement atteint sous kDebugMode (cf. bas de la page).
import 'package:school_app_flutter/dev/dev_tools_entry.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_brand_banner.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_entrance.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_modules_section.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_signature.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page d'atterrissage post-connexion (spec Accueil).
///
/// Rôle : orienter. Bandeau de marque (statique) → section modules (les six
/// portes d'entrée de l'application) → signature. Pas de synthèse chiffrée :
/// les modules eux-mêmes sont le cœur de la page (spec §00).
///
/// La grille est construite à partir de la copy localisée, sans appel réseau :
/// elle ne traverse donc aucune machine à états (chargement / vide / erreur) —
/// il n'y a rien à charger.
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  /// Le bandeau ouvre la séquence d'entrée ; les cartes suivent, décalées de
  /// 60 ms chacune.
  static const int _bannerEntranceIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // `select` plutôt que `read` : un refresh porteur d'un nouvel ensemble de
    // droits recompose la grille sans rien d'impératif (ADR-014 §5).
    final permissions = context.select<AuthBloc, List<String>>(
      (bloc) => bloc.state.permissions,
    );
    final modules = AccueilModulesFactory.create(
      l10n,
      permissions: permissions,
    );

    return AppPageBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccueilEntrance(
            index: _bannerEntranceIndex,
            child: AccueilBrandBanner(),
          ),
          const SizedBox(height: AccueilUiTokens.bannerToModulesGap),
          AccueilModulesSection(
            modules: modules,
            entranceIndexOffset: _bannerEntranceIndex + 1,
          ),
          const SizedBox(height: AccueilUiTokens.modulesToSignatureGap),
          const AccueilSignature(),
          // Seul endroit de l'application d'où l'on atteint `/dev/components` et
          // `/dev/ticket-print` : les deux routes existent depuis toujours mais
          // n'étaient référencées nulle part. `kDebugMode` étant une constante
          // de compilation, la branche entière disparaît du build release —
          // même mécanisme que les `GoRoute` correspondantes.
          if (kDebugMode) const DevToolsEntry(),
        ],
      ),
    );
  }
}
