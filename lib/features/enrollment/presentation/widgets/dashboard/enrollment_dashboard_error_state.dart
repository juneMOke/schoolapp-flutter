import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/enrollment/presentation/extensions/enrollment_dashboard_failure_l10n_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'erreur du tableau de bord des inscriptions, sur l'anatomie partagée.
///
/// **Elle remplace TOUT le contenu sous l'en-tête** — bandeau d'effectif et
/// onglets compris. C'est une règle de la spec, et sa raison est simple : sans
/// données, l'effectif affiché serait un mensonge. Le bloc s'en assure en
/// vidant `stats` à l'échec ; cette vue n'a donc rien à masquer, elle occupe
/// seulement la place.
///
/// Quatre familles, **quatre gestes différents** :
///
///  - **réseau** → Réessayer ;
///  - **401** → le message dit de se reconnecter ; la reprise, elle, est
///    globale (intercepteur d'authentification), donc aucun bouton ici — deux
///    chemins de reconnexion seraient deux chemins à tenir d'accord ;
///  - **403** → aucune action. Réessayer un droit qu'on n'a pas ne le donne
///    pas, et proposer le bouton invite à s'acharner ;
///  - **500 / stockage** → Réessayer, avec le code d'incident à citer.
///
/// ⚠️ Le piège du mapping, que AGENTS.md signale explicitement : **401 arrive
/// en `InvalidCredentialsFailure` et 403 en `UnauthorizedFailure`**. Le nom
/// `Unauthorized` invite à le lire comme un 401 ; le brancher ainsi afficherait
/// « Se reconnecter » à un enseignant à qui il manque un droit, et il se
/// déconnecterait en boucle sans jamais obtenir la page.
class EnrollmentDashboardErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const EnrollmentDashboardErrorState({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = _typeOf(failure);
    final incidentCode = failure is ApiErrorDetails
        ? (failure as ApiErrorDetails).incidentId
        : null;

    return EteeloErrorResult(
      type: type,
      title: _title(l10n, type),
      message: failure.enrollmentDashboardMessage(l10n),
      primaryAction: _action(l10n, type),
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incidentCode != null &&
              incidentCode.trim().isNotEmpty
          ? l10n.enrollmentDashboardErrorIncidentCode(incidentCode)
          : null,
      fullWidthCard: true,
    );
  }

  static EteeloErrorType _typeOf(Failure failure) => switch (failure) {
    NetworkFailure() => EteeloErrorType.network,
    // 401 — la session a expiré.
    InvalidCredentialsFailure() ||
    AuthFailure() => EteeloErrorType.unauthorized,
    // 403 — le droit manque. Voir l'avertissement en tête de classe.
    UnauthorizedFailure() => EteeloErrorType.forbidden,
    // Le stockage rejoint le serveur : dans les deux cas la donnée n'a pas pu
    // être lue, et le geste est le même.
    ServerFailure() || StorageFailure() => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };

  String _title(AppLocalizations l10n, EteeloErrorType type) => switch (type) {
    EteeloErrorType.network => l10n.enrollmentDashboardErrorNetworkTitle,
    EteeloErrorType.unauthorized =>
      l10n.enrollmentDashboardErrorUnauthorizedTitle,
    EteeloErrorType.forbidden => l10n.enrollmentDashboardErrorForbiddenTitle,
    EteeloErrorType.server ||
    EteeloErrorType.unknown => l10n.enrollmentDashboardErrorServerTitle,
  };

  Widget? _action(AppLocalizations l10n, EteeloErrorType type) =>
      switch (type) {
        // Les deux cas où l'absence de bouton EST le bon message.
        EteeloErrorType.forbidden || EteeloErrorType.unauthorized => null,
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.enrollmentDashboardErrorRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      };
}
