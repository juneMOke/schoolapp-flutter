import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État « aucun module accessible » de la page d'accueil (ADR-014 §2.8).
///
/// Le fail-closed produit une grille vide dans trois cas : un rôle
/// délibérément sans droits (`PARENT`, `STUDENT`), un compte réellement
/// dépouillé, et — transitoirement — un compte dont l'application vient d'être
/// mise à jour et qui ne s'est pas encore reconnecté en ligne. Sans cet écran,
/// les trois se lisent de la même façon : une page blanche, qu'un utilisateur
/// prend pour une panne.
///
/// **Anatomie 403** (règle des états partagés) : aucun « Réessayer », puisque
/// rien de ce que l'utilisateur peut faire ici ne changera son périmètre.
///
/// Trois variantes, parce que trois causes différentes appellent trois gestes
/// différents :
///
/// - **droits inconnus** ([permissionsUnknown]) : rien n'a jamais été
///   communiqué pour ce compte sur cet appareil — session ouverte avant que
///   l'application ne sache lire les permissions, ou réponse serveur sans le
///   champ. Ce n'est pas un retrait de droits, et le dire évite d'envoyer
///   l'agent réclamer à son administration ce qu'une reconnexion suffit à
///   récupérer ;
/// - **hors ligne** : les droits viennent de la copie durable du dernier
///   contact serveur ; une reconnexion en ligne peut les rafraîchir — on le
///   dit, sans offrir un bouton qui ne peut pas aboutir sans réseau ;
/// - **en ligne, ensemble vide** : le serveur a parlé. Seule l'administration
///   de l'école peut y changer quelque chose, et se reconnecter est la seule
///   action utile à portée de main.
class AccueilNoAccessState extends StatelessWidget {
  const AccueilNoAccessState({
    super.key,
    required this.isOffline,
    this.permissionsUnknown = false,
  });

  final bool isOffline;

  /// L'ensemble effectif est `null` : jamais communiqué, à ne pas confondre
  /// avec un ensemble vide, qui est une décision du serveur.
  final bool permissionsUnknown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloErrorResult(
      type: EteeloErrorType.forbidden,
      fullWidthCard: false,
      title: permissionsUnknown
          ? l10n.accueilUnknownRightsTitle
          : l10n.accueilNoAccessTitle,
      message: permissionsUnknown
          ? l10n.accueilUnknownRightsMessage
          : isOffline
          ? l10n.accueilNoAccessOfflineMessage
          : l10n.accueilNoAccessMessage,
      // Hors ligne, se déconnecter ferait perdre la session sans pouvoir en
      // rouvrir une : le bouton serait un piège, quelle que soit la cause.
      primaryAction: isOffline
          ? null
          : OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.signOutAction),
            ),
    );
  }
}
