import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'erreur de la caisse, sur l'anatomie partagée : médaillon, titre, message,
/// action de récupération.
///
/// Quatre familles, **quatre gestes différents** — et c'est pourquoi elles ne se
/// replient pas l'une sur l'autre :
///
///  - **réseau** → Réessayer. Le panier en cours est conservé : une coupure ne
///    fait pas perdre une vente en composition.
///  - **401** → Se reconnecter.
///  - **403** → contacter la direction, et **jamais « Réessayer »** : réessayer
///    un droit qu'on n'a pas ne le donne pas. Cas réel — un enseignant arrive
///    sur l'URL de la boutique.
///  - **500 / stockage** → Réessayer, avec le code d'incident à citer.
class BoutiqueResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  /// L'écran qui échoue — c'est lui qui décide ce que le message NOMME.
  ///
  /// Les quatre familles et leurs quatre gestes sont partagés ; les phrases, non.
  /// L'historique annonçant « le catalogue local n'a pas pu être lu » ferait
  /// chercher une panne de catalogue à qui vient consulter sa caisse, et le
  /// message réseau y serait carrément faux : l'historique se lit en local.
  final BoutiqueErrorSurface surface;

  const BoutiqueResultsErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.onReconnect,
    this.surface = BoutiqueErrorSurface.catalog,
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
      message: _message(l10n, type),
      primaryAction: _action(l10n, type),
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incidentCode != null &&
              incidentCode.trim().isNotEmpty
          ? l10n.boutiqueErrorIncidentCode(incidentCode)
          : null,
      fullWidthCard: true,
    );
  }

  static EteeloErrorType _typeOf(Failure failure) => switch (failure) {
    NetworkFailure() => EteeloErrorType.network,
    InvalidCredentialsFailure() ||
    AuthFailure() => EteeloErrorType.unauthorized,
    UnauthorizedFailure() => EteeloErrorType.forbidden,
    // Le stockage rejoint le serveur : dans les deux cas la donnée n'a pas pu
    // être lue, et le geste est le même — réessayer, puis appeler à l'aide.
    ServerFailure() || StorageFailure() => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };

  Widget? _action(AppLocalizations l10n, EteeloErrorType type) =>
      switch (type) {
        // 403 : AUCUNE action de reprise. C'est le seul cas où l'absence de
        // bouton est le bon message.
        EteeloErrorType.forbidden => null,
        EteeloErrorType.unauthorized =>
          onReconnect == null
              ? null
              : EteeloButton.primary(
                  label: l10n.boutiqueErrorReconnect,
                  icon: Icons.login,
                  onPressed: onReconnect,
                  fullWidth: false,
                ),
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.boutiqueErrorRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      };

  String _title(AppLocalizations l10n, EteeloErrorType type) => switch (type) {
    EteeloErrorType.network => l10n.boutiqueErrorNetworkTitle,
    EteeloErrorType.unauthorized => l10n.boutiqueErrorUnauthorizedTitle,
    EteeloErrorType.forbidden => l10n.boutiqueErrorForbiddenTitle,
    EteeloErrorType.server || EteeloErrorType.unknown =>
      surface == BoutiqueErrorSurface.history
          ? l10n.boutiqueHistoryErrorServerTitle
          : l10n.boutiqueErrorServerTitle,
  };

  String _message(AppLocalizations l10n, EteeloErrorType type) =>
      switch (type) {
        EteeloErrorType.network =>
          surface == BoutiqueErrorSurface.history
              ? l10n.boutiqueHistoryErrorNetwork
              : l10n.boutiqueErrorNetwork,
        EteeloErrorType.unauthorized => l10n.boutiqueErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.boutiqueErrorForbidden,
        EteeloErrorType.server || EteeloErrorType.unknown =>
          surface == BoutiqueErrorSurface.history
              ? l10n.boutiqueHistoryErrorServer
              : l10n.boutiqueErrorServer,
      };
}

/// Quel écran de la caisse échoue. Les gestes de reprise sont les mêmes ; ce que
/// les phrases NOMMENT ne l'est pas.
enum BoutiqueErrorSurface { catalog, history }
