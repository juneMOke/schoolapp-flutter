import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'assistant doit faire d'un échec.
///
/// Nommé plutôt que déduit à l'affichage : deux échecs de même statut HTTP
/// peuvent appeler des conduites opposées, et c'est le **code typé** du serveur
/// qui tranche — jamais son message, rédigé pour un humain et sujet à
/// reformulation.
enum ConfigurationErrorKind {
  /// Réseau ou hors-ligne. Réessai **manuel**, jamais automatique.
  network,

  /// 401 : reconnexion. Le brouillon local reste intact.
  session,

  /// 403 : rien à réessayer, seul un changement de droits y remédie.
  forbidden,

  /// 422 « code inconnu » : le catalogue en mémoire est périmé.
  staleCatalog,

  /// 400 `BUSINESS_RULE` : l'année existe déjà pour cette école.
  yearAlreadyExists,

  /// 429 : attendre. Surtout pas de « Réessayer ».
  rateLimited,

  /// 5xx, avec sa référence d'incident quand le serveur en pose une.
  server,
}

/// Classe un échec.
ConfigurationErrorKind classifyConfigurationFailure(Failure failure) {
  if (failure is TooManyRequestsFailure) {
    return ConfigurationErrorKind.rateLimited;
  }
  if (failure is InvalidCredentialsFailure) {
    return ConfigurationErrorKind.session;
  }
  if (failure is UnauthorizedFailure) return ConfigurationErrorKind.forbidden;
  if (failure is ApiValidationFailure) {
    return switch (failure.code) {
      // Le refus qui compte : le paramétrage est un geste d'amorçage, il ne
      // complète pas une école déjà ouverte. Y répondre par « Réessayer »
      // ferait boucler l'agent sur le même refus.
      ApiErrorCode.businessRule => ConfigurationErrorKind.yearAlreadyExists,
      // Un code que le serveur ne connaît pas signale un catalogue périmé en
      // mémoire — le recharger est la seule action qui change quelque chose.
      ApiErrorCode.unprocessable => ConfigurationErrorKind.staleCatalog,
      _ => ConfigurationErrorKind.network,
    };
  }
  if (failure is ApiServerFailure || failure is ServerFailure) {
    return ConfigurationErrorKind.server;
  }
  if (failure is UncertainOutcomeFailure) {
    return ConfigurationErrorKind.server;
  }
  return ConfigurationErrorKind.network;
}

/// Le bloc d'erreur de l'assistant.
///
/// **Rendu dans la carte de l'étape, jamais seulement en toast** : un toast
/// disparaît, et l'agent qui revient à l'écran ne saurait plus ce qui a échoué.
class ConfigurationErrorView extends StatelessWidget {
  final Failure failure;

  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;
  final VoidCallback? onReloadCatalog;
  final VoidCallback? onBackToYear;

  const ConfigurationErrorView({
    super.key,
    required this.failure,
    this.onRetry,
    this.onSignIn,
    this.onReloadCatalog,
    this.onBackToYear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kind = classifyConfigurationFailure(failure);
    final currentFailure = failure;
    final incidentId = currentFailure is ApiErrorDetails
        ? currentFailure.incidentId
        : null;

    final (type, title, message) = switch (kind) {
      ConfigurationErrorKind.network => (
        EteeloErrorType.network,
        l10n.configurationErrorNetworkTitle,
        l10n.configurationErrorNetworkMessage,
      ),
      ConfigurationErrorKind.session => (
        EteeloErrorType.unauthorized,
        l10n.configurationErrorSessionTitle,
        l10n.configurationErrorSessionMessage,
      ),
      ConfigurationErrorKind.forbidden => (
        EteeloErrorType.forbidden,
        l10n.configurationErrorForbiddenTitle,
        l10n.configurationErrorForbiddenMessage,
      ),
      ConfigurationErrorKind.staleCatalog => (
        EteeloErrorType.unknown,
        l10n.configurationErrorNetworkTitle,
        // Le message du serveur nomme le niveau ou le code fautif : il est plus
        // précis que tout ce qu'on pourrait rédiger ici.
        _serverMessage(failure) ?? l10n.configurationErrorNetworkMessage,
      ),
      ConfigurationErrorKind.yearAlreadyExists => (
        EteeloErrorType.unknown,
        l10n.configurationErrorYearExistsTitle,
        l10n.configurationErrorYearExistsMessage,
      ),
      ConfigurationErrorKind.rateLimited => (
        EteeloErrorType.unknown,
        l10n.configurationErrorRateTitle,
        l10n.configurationErrorRateMessage,
      ),
      ConfigurationErrorKind.server => (
        EteeloErrorType.server,
        l10n.configurationErrorServerTitle,
        l10n.configurationErrorServerMessage,
      ),
    };

    return EteeloErrorResult(
      type: type,
      fullWidthCard: true,
      title: title,
      message: message,
      // La référence que l'utilisateur cite au support, affichée telle quelle.
      // En fabriquer une côté client donnerait un code que rien ne permettrait
      // de retrouver.
      incidentCodeLabel: incidentId == null
          ? null
          : '${l10n.configurationErrorIncident} $incidentId',
      primaryAction: switch (kind) {
        // Le 403 ne propose jamais « Réessayer » : rien de ce que
        // l'utilisateur peut faire ici ne changera la réponse du serveur.
        ConfigurationErrorKind.forbidden => null,
        // Le 429 non plus : ce serait l'inviter à reproduire exactement ce qui
        // vient d'être refusé.
        ConfigurationErrorKind.rateLimited => null,
        ConfigurationErrorKind.session => _action(
          onSignIn,
          Icons.login_rounded,
          l10n.configurationErrorSignIn,
        ),
        ConfigurationErrorKind.staleCatalog => _action(
          onReloadCatalog,
          Icons.sync_rounded,
          l10n.configurationErrorReloadCatalog,
        ),
        ConfigurationErrorKind.yearAlreadyExists => _action(
          onBackToYear,
          Icons.event_rounded,
          l10n.configurationErrorYearExistsAction,
        ),
        _ => _action(
          onRetry,
          Icons.refresh_rounded,
          l10n.configurationErrorRetry,
        ),
      },
    );
  }

  static Widget? _action(VoidCallback? onPressed, IconData icon, String label) {
    if (onPressed == null) return null;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  static String? _serverMessage(Failure failure) =>
      failure is ApiErrorDetails ? failure.serverMessage : null;
}
