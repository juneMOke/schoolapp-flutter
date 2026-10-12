import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/communication_failure_text.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/states/communication_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'une zone de résultats du module (règle n° 10) : une anatomie,
/// quatre tonalités. Le module est en ligne : réseau (Réessayer), 401 (se
/// reconnecter), 403 (contacter l'administrateur — jamais « Réessayer »),
/// 500 (Réessayer, avec le code d'incident).
class CommunicationResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const CommunicationResultsErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = incidentOf(failure);
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.communicationErrorNetworkTitle,
        EteeloErrorType.unauthorized =>
          l10n.communicationErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.communicationErrorForbiddenTitle,
        _ => l10n.communicationErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.communicationErrorNetwork,
        EteeloErrorType.unauthorized => l10n.communicationErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.communicationErrorForbidden,
        _ => l10n.communicationErrorServer,
      },
      primaryAction: communicationErrorAction(
        context,
        type,
        onRetry: onRetry,
        prominent: true,
      ),
      incidentCodeLabel: type == EteeloErrorType.server && incident != null
          ? l10n.communicationErrorIncident(incident)
          : null,
    );
  }
}
