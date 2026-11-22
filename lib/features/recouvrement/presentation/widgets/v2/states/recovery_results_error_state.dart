import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'une zone de résultats du tableau de bord du Recouvrement (règle
/// n° 10) : réseau (Réessayer), 401 (se reconnecter), 403 (« Contacter
/// l'administrateur » seul, jamais « Réessayer » — A16), 500 (Réessayer et le
/// code d'incident). Les actions sont celles de la Trésorerie, l'autre module
/// en ligne : un même geste pour une même famille d'échec.
class RecoveryResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  /// La liste nominative : le 403 y dit qu'il manque le droit de voir les
  /// noms, les chiffres au-dessus restant lisibles.
  final bool nominative;

  const RecoveryResultsErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
    this.nominative = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = treasuryIncidentOf(failure);
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.recoveryErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.recoveryErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.recoveryErrorForbiddenTitle,
        _ => l10n.recoveryErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.recoveryErrorNetwork,
        EteeloErrorType.unauthorized => l10n.recoveryErrorUnauthorized,
        EteeloErrorType.forbidden =>
          nominative
              ? l10n.recoveryErrorForbiddenList
              : l10n.recoveryErrorForbidden,
        _ => l10n.recoveryErrorServer,
      },
      primaryAction: treasuryErrorAction(
        context,
        type,
        onRetry: onRetry,
        prominent: true,
      ),
      incidentCodeLabel: type == EteeloErrorType.server && incident != null
          ? l10n.recoveryErrorIncident(incident)
          : null,
    );
  }
}
