import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Vue d'échec du splash (spec §00 : « l'ErrorView, réutilisé tel quel quand
/// l'amorçage échoue »). Affichée à la place du chargement quand la résolution
/// du contexte académique échoue, avec un bouton « Réessayer » qui relance
/// l'amorçage.
///
/// Le réessai passe par [AcademicYearContextRetryRequested] : le widget signale
/// l'intention et le bloc relance lui-même le chargement (pas de remote
/// déclenché directement depuis un widget).
///
/// Trois anatomies (règle §"États partagés") : réseau, avec « Réessayer » ;
/// **403** quand le compte n'a pas la permission d'amorçage — celle-ci ne
/// propose jamais de réessayer, puisque rien de ce que l'utilisateur peut faire
/// ici ne changera la réponse du serveur ; et **école non paramétrée**, qui n'est
/// pas une erreur du tout.
///
/// Cette troisième existe parce que la deuxième mentait. Une école fraîchement
/// souscrite n'a aucune année académique : le pull aboutit, le référentiel est
/// vide, et l'écran affichait « Connexion impossible — vérifiez votre
/// connexion » avec un bouton « Réessayer » qui ne pouvait par construction
/// jamais aboutir. Rien dans le geste de réessayer ne crée une année scolaire.
class SplashErrorView extends StatelessWidget {
  const SplashErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final forbidden = context.select<AcademicYearContextBloc, bool>(
      (bloc) => bloc.state.insufficientPermissions,
    );
    final notProvisioned = context.select<AcademicYearContextBloc, bool>(
      (bloc) => bloc.state.schoolNotProvisioned,
    );

    if (notProvisioned) {
      return const _SchoolNotProvisionedView();
    }

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

/// L'école n'a pas encore été paramétrée : un état légitime du produit, pas un
/// incident.
///
/// L'issue dépend de qui regarde. Le promoteur ouvre l'assistant ; un agent de
/// secrétariat, lui, ne peut rien y faire — et lui offrir un bouton qui rend 403
/// serait le renvoyer contre une porte fermée. On lui dit donc quoi attendre, et
/// de qui.
class _SchoolNotProvisionedView extends StatelessWidget {
  const _SchoolNotProvisionedView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canProvision = context.select<AuthBloc, bool>(
      (bloc) => canAccess(
        requires: const [Perm.schoolProvisioningWrite],
        permissions: bloc.state.permissions,
      ),
    );

    // `EteeloEmptyResult` et non `EteeloErrorResult` : rien n'a échoué. Cette
    // école n'a simplement pas encore d'année — l'anatomie d'état vide dit « il
    // n'y a rien encore », ce qui est exactement le cas (règle projet §10).
    return EteeloEmptyResult(
      medallionIcon: Icons.tune_rounded,
      accentColor: AppColors.terreCuite,
      label: l10n.splashNotProvisionedTitle,
      description: canProvision
          ? l10n.splashNotProvisionedMessage
          : l10n.splashNotProvisionedWaitMessage,
      primaryAction: canProvision
          ? FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutesNames.configuration),
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.splashNotProvisionedAction),
            )
          : OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.signOutAction),
            ),
    );
  }
}
