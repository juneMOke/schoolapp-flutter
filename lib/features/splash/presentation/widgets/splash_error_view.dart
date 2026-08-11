import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue d'échec du splash (spec §00 : « l'ErrorView, réutilisé tel quel quand
/// l'amorçage échoue »). Affichée à la place du chargement quand la résolution
/// du contexte académique échoue, avec un bouton « Réessayer » qui relance
/// l'amorçage.
///
/// Le réessai passe par [AcademicYearContextRetryRequested] : le widget signale
/// l'intention et le bloc relance lui-même le chargement (pas de remote
/// déclenché directement depuis un widget).
///
/// Deux anatomies (règle §"États partagés") : réseau, avec « Réessayer », et
/// **403** quand le compte n'a pas la permission d'amorçage — celle-ci ne
/// propose jamais de réessayer, puisque rien de ce que l'utilisateur peut faire
/// ici ne changera la réponse du serveur.
class SplashErrorView extends StatelessWidget {
  const SplashErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final forbidden = context.select<AcademicYearContextBloc, bool>(
      (bloc) => bloc.state.insufficientPermissions,
    );

    // EteeloErrorResult gère lui-même son centrage et sa contrainte de hauteur
    // (il est conçu pour un parent borné — ici la SafeArea du splash). Ne pas
    // l'envelopper dans un Center/SingleChildScrollView : cela lui donnerait une
    // hauteur non bornée et le ferait s'effondrer.
    return EteeloErrorResult(
      type: forbidden ? EteeloErrorType.forbidden : EteeloErrorType.network,
      // Carte centrée (et non pleine largeur) : effet modale sur le fond sombre.
      fullWidthCard: false,
      title: forbidden ? l10n.splashForbiddenTitle : l10n.splashErrorTitle,
      message: forbidden
          ? l10n.splashForbiddenMessage
          : l10n.splashErrorMessage,
      // Le 403 ne propose pas de réessayer — mais il doit proposer QUELQUE
      // CHOSE : le routeur retient sur le splash tant que le contexte académique
      // est en échec bloquant, et la session survit au redémarrage. Sans cette
      // sortie, l'appareil reste immobilisé sur ce compte, et le seul recours à
      // portée de l'agent — effacer les données de l'application — détruirait
      // l'outbox avec elles.
      primaryAction: forbidden
          ? OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.signOutAction),
            )
          : FilledButton.icon(
              onPressed: () => context.read<AcademicYearContextBloc>().add(
                const AcademicYearContextRetryRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.splashErrorRetry),
            ),
    );
  }
}
