import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue d'échec du splash (spec §00 : « l'ErrorView, réutilisé tel quel quand
/// l'amorçage échoue »). Affichée à la place du chargement quand le bootstrap
/// distant échoue, avec un bouton « Réessayer » qui relance l'amorçage.
///
/// Le réessai passe par [BootstrapRetryRequested] : le widget signale l'intention
/// et le bloc relance lui-même les fetch distants (règle du module bootstrap :
/// pas de remote déclenché directement depuis un widget).
class SplashErrorView extends StatelessWidget {
  const SplashErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // EteeloErrorResult gère lui-même son centrage et sa contrainte de hauteur
    // (il est conçu pour un parent borné — ici la SafeArea du splash). Ne pas
    // l'envelopper dans un Center/SingleChildScrollView : cela lui donnerait une
    // hauteur non bornée et le ferait s'effondrer.
    return EteeloErrorResult(
      // L'échec d'amorçage est presque toujours d'origine réseau.
      type: EteeloErrorType.network,
      // Carte centrée (et non pleine largeur) : effet modale sur le fond sombre.
      fullWidthCard: false,
      title: l10n.splashErrorTitle,
      message: l10n.splashErrorMessage,
      primaryAction: FilledButton.icon(
        onPressed: () =>
            context.read<BootstrapBloc>().add(const BootstrapRetryRequested()),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.splashErrorRetry),
      ),
    );
  }
}
