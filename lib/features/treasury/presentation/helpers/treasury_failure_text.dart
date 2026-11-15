import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pourquoi un appel de la trésorerie a échoué, en une phrase qui suit sa
/// cause : on ne dit pas « vérifiez la connexion » à qui s'est vu refuser un
/// droit, ni « réessayez » quand la caisse est déjà clôturée.
extension TreasuryFailureText on AppLocalizations {
  String treasuryFailureReason(Failure failure) {
    if (failure is TreasuryRefusalFailure) {
      return switch (failure.refusal) {
        TreasuryRefusal.cashDayAlreadyClosed => treasuryReasonClosed,
        TreasuryRefusal.currencyAlreadyHasRegister =>
          treasuryReasonCurrencyTaken,
        TreasuryRefusal.registerNameTaken => treasuryDuplicateName,
        TreasuryRefusal.reasonRequired => treasuryAdjustReasonShort,
        TreasuryRefusal.noChange => treasuryAdjustNoChange,
        TreasuryRefusal.expectedChanged => treasuryReasonExpectedChanged,
        TreasuryRefusal.afterClosureUnconfirmed =>
          treasuryReasonAfterClosurePending,
        TreasuryRefusal.afterClosureAlreadyConfirmed =>
          treasuryReasonAlreadyAnswered,
        TreasuryRefusal.notAfterClosure => treasuryReasonNotAfterClosure,
        TreasuryRefusal.afterClosureNotCovered =>
          treasuryReasonAfterClosureNotCovered,
        TreasuryRefusal.gestureIdReused => treasuryReasonGestureIdReused,
        TreasuryRefusal.signatoriesChanged => treasuryReasonSignatoriesChanged,
        TreasuryRefusal.signatoryFieldRequired ||
        TreasuryRefusal.signatoryFieldTooLong ||
        TreasuryRefusal.tooManySignatories ||
        TreasuryRefusal.invalidSignatoryRank ||
        TreasuryRefusal.closerOnlyAtRankOne => treasuryReasonSignatoriesInvalid,
        TreasuryRefusal.closureNotToday ||
        TreasuryRefusal.reopenNotToday => treasuryReasonNotToday,
        TreasuryRefusal.gapJustificationRequired => treasuryGapReasonShort,
        TreasuryRefusal.invalidDeclaration => treasuryReasonInvalidDeclaration,
        TreasuryRefusal.closureAlreadyReopened => treasuryReasonAlreadyReopened,
        TreasuryRefusal.invalidDate => treasuryReasonInvalidDate,
        TreasuryRefusal.invalidRange => treasuryReasonInvalidRange,
        TreasuryRefusal.invalidReportId => treasuryReasonInvalidReportId,
      };
    }
    return switch (EteeloErrorType.fromFailure(failure)) {
      EteeloErrorType.network => treasuryReasonNetwork,
      EteeloErrorType.unauthorized => treasuryErrorUnauthorized,
      EteeloErrorType.forbidden => treasuryReasonForbidden,
      _ => treasuryReasonServer,
    };
  }
}

/// La référence d'un incident serveur, quand l'échec en porte une.
String? treasuryIncidentOf(Failure failure) {
  final incident = failure is ApiErrorDetails ? failure.incidentId : null;
  return incident == null || incident.trim().isEmpty ? null : incident;
}
