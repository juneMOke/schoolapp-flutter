import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pourquoi un appel a échoué, en une phrase qui suit sa famille : on ne dit
/// pas « vérifiez la connexion » à qui s'est vu refuser un droit.
extension CommunicationFailureText on AppLocalizations {
  String failureReason(Failure failure) =>
      switch (EteeloErrorType.fromFailure(failure)) {
        EteeloErrorType.network => communicationReasonNetwork,
        EteeloErrorType.unauthorized => communicationErrorUnauthorized,
        EteeloErrorType.forbidden => communicationReasonForbidden,
        _ => communicationReasonServer,
      };
}

/// La référence d'un incident serveur, quand l'échec en porte une.
String? incidentOf(Failure failure) {
  final incident = failure is ApiErrorDetails ? failure.incidentId : null;
  return incident == null || incident.trim().isEmpty ? null : incident;
}
