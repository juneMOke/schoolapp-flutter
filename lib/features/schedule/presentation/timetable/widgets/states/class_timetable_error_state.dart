import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'erreur en place de l'emploi du temps (règle 10) : réseau, 401, 403,
/// serveur. Un 403 ne propose jamais « Réessayer » — seulement « Contacter
/// l'administrateur ». Les actions sont celles de la trésorerie, qui portent
/// déjà cette anatomie (`treasuryErrorAction`).
class ClassTimetableErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const ClassTimetableErrorState({
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
        EteeloErrorType.network => l10n.classTimetableErrorNetworkTitle,
        EteeloErrorType.unauthorized =>
          l10n.classTimetableErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.classTimetableErrorForbiddenTitle,
        _ => l10n.classTimetableErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.classTimetableErrorNetwork,
        EteeloErrorType.unauthorized => l10n.classTimetableError401,
        EteeloErrorType.forbidden => l10n.classTimetableError403,
        _ => l10n.classTimetableErrorServer,
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
