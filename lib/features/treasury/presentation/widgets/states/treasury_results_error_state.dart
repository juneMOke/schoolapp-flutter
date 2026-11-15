import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'une zone de résultats du module (règle n° 10) : une anatomie,
/// quatre tonalités. Le module est en ligne : réseau (Réessayer), 401 (se
/// reconnecter), 403 (contacter l'administrateur — jamais « Réessayer »),
/// 500 (Réessayer, avec le code d'incident).
class TreasuryResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const TreasuryResultsErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = treasuryIncidentOf(failure);
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.treasuryErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.treasuryErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.treasuryErrorForbiddenTitle,
        _ => l10n.treasuryErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.treasuryErrorNetwork,
        EteeloErrorType.unauthorized => l10n.treasuryErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.treasuryErrorForbidden,
        _ => l10n.treasuryErrorServer,
      },
      primaryAction: treasuryErrorAction(
        context,
        type,
        onRetry: onRetry,
        prominent: true,
      ),
      incidentCodeLabel: type == EteeloErrorType.server && incident != null
          ? l10n.treasuryErrorIncident(incident)
          : null,
    );
  }
}
