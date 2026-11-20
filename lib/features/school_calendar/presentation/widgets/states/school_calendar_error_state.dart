import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'erreur en place du calendrier scolaire (règle 10) : réseau, 401, 403,
/// serveur. Un 403 ne propose jamais « Réessayer » — seulement « Contacter
/// l'administrateur ». Les actions sont celles de la trésorerie, qui portent
/// déjà cette anatomie (`treasuryErrorAction`).
class SchoolCalendarErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const SchoolCalendarErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.schoolCalendarErrorNetworkTitle,
        EteeloErrorType.unauthorized =>
          l10n.schoolCalendarErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.schoolCalendarErrorForbiddenTitle,
        _ => l10n.schoolCalendarErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.schoolCalendarErrorNetwork,
        EteeloErrorType.unauthorized => l10n.schoolCalendarError401,
        EteeloErrorType.forbidden => l10n.schoolCalendarError403,
        _ => l10n.schoolCalendarErrorServer,
      },
      primaryAction: treasuryErrorAction(
        context,
        type,
        onRetry: onRetry,
        prominent: true,
      ),
    );
  }
}
