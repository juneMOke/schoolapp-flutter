import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/finance_stats_failure_l10n_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'erreur du pilotage financier, sur l'anatomie partagée : médaillon, titre,
/// message, action de récupération.
///
/// Quatre familles, **quatre gestes différents** :
///
///  - **réseau** → Réessayer ;
///  - **401** → Se reconnecter ;
///  - **403** → contacter la direction, et **jamais « Réessayer »** : réessayer
///    un droit qu'on n'a pas ne le donne pas. Cas réel — un enseignant arrive
///    sur l'URL du tableau de bord ;
///  - **500 / stockage** → Réessayer, avec le code d'incident à citer.
///
/// [onReconnect] reste `null` sur les écrans de pilotage, comme partout
/// ailleurs dans le dépôt : l'expiration de session est reprise **globalement**
/// (intercepteur d'authentification, bandeau de dégradation), et offrir ici un
/// second chemin de reconnexion en ferait deux à tenir d'accord. Le message,
/// lui, dit quoi faire.
///
/// ## Le titre vient de la famille, le message du `Failure`
///
/// Quatre titres suffisent à dire ce qui se passe, mais neuf messages disent ce
/// qui s'est passé — « les paramètres demandés sont invalides » n'est pas « le
/// serveur est indisponible », et les replier tous les deux sous un même texte
/// perdrait la seule information qui distingue un bug de l'application d'une
/// panne du serveur.
class FinanceStatsResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  const FinanceStatsResultsErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.onReconnect,
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
      message: failure.financeStatsMessage(l10n),
      primaryAction: _action(l10n, type),
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incidentCode != null &&
              incidentCode.trim().isNotEmpty
          ? l10n.financeStatsErrorIncidentCode(incidentCode)
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

  String _title(AppLocalizations l10n, EteeloErrorType type) => switch (type) {
    EteeloErrorType.network => l10n.financeStatsErrorNetworkTitle,
    EteeloErrorType.unauthorized => l10n.financeStatsErrorUnauthorizedTitle,
    EteeloErrorType.forbidden => l10n.financeStatsErrorForbiddenTitle,
    EteeloErrorType.server ||
    EteeloErrorType.unknown => l10n.financeStatsErrorServerTitle,
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
                  label: l10n.financeStatsErrorReconnect,
                  icon: Icons.login,
                  onPressed: onReconnect,
                  fullWidth: false,
                ),
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.financeStatsRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      };
}
