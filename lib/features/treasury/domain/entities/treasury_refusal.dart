import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';

/// Les refus métier de la trésorerie, tels que le serveur les nomme dans
/// `ApiError.detailCode` (contrat PR back #222). Chacun appelle une conduite
/// différente à l'écran : c'est pourquoi on ne les réduit jamais à un
/// « conflit » générique.
enum TreasuryRefusal {
  currencyAlreadyHasRegister('CURRENCY_ALREADY_HAS_REGISTER'),
  registerNameTaken('REGISTER_NAME_TAKEN'),
  cashDayAlreadyClosed('CASH_DAY_ALREADY_CLOSED'),
  expectedChanged('EXPECTED_CHANGED'),
  reasonRequired('REASON_REQUIRED'),
  noChange('NO_CHANGE'),
  // ── Clôture (R9, R19, R20) ──
  afterClosureUnconfirmed('AFTER_CLOSURE_UNCONFIRMED'),
  afterClosureAlreadyConfirmed('AFTER_CLOSURE_ALREADY_CONFIRMED'),
  notAfterClosure('NOT_AFTER_CLOSURE'),
  closureNotToday('CLOSURE_NOT_TODAY'),
  gapJustificationRequired('GAP_JUSTIFICATION_REQUIRED'),
  invalidDeclaration('INVALID_DECLARATION'),
  closureAlreadyReopened('CLOSURE_ALREADY_REOPENED'),
  reopenNotToday('REOPEN_NOT_TODAY'),
  invalidDate('INVALID_DATE'),
  invalidRange('INVALID_RANGE');

  const TreasuryRefusal(this.detailCode);

  final String detailCode;

  static TreasuryRefusal? fromDetailCode(String? code) {
    if (code == null) return null;
    for (final refusal in values) {
      if (refusal.detailCode == code) return refusal;
    }
    return null;
  }
}

/// Un refus métier de la trésorerie, avec les faits chiffrés qu'il porte
/// (`details`), par exemple l'attendu serveur d'un `EXPECTED_CHANGED`.
class TreasuryRefusalFailure extends Failure {
  final TreasuryRefusal refusal;
  final Map<String, dynamic> details;

  /// La clôture enregistrée, quand le refus la porte
  /// (`CASH_DAY_ALREADY_CLOSED`, `CLOSURE_ALREADY_REOPENED`) : l'écran la
  /// montre et ne rejoue jamais le geste.
  final CashClosure? closure;

  const TreasuryRefusalFailure(
    this.refusal, {
    this.details = const {},
    this.closure,
  }) : super('Refus de la trésorerie');

  /// L'attendu actuel du serveur, quand le refus le donne.
  int? get serverExpectedInCents =>
      (details['expectedInCents'] as num?)?.toInt();

  @override
  List<Object?> get props => [refusal, details, closure];
}
