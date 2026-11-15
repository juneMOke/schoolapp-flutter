import 'package:school_app_flutter/core/error/failures.dart';

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
  noChange('NO_CHANGE');

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

  const TreasuryRefusalFailure(this.refusal, {this.details = const {}})
    : super('Refus de la trésorerie');

  /// L'attendu actuel du serveur, quand le refus le donne.
  int? get serverExpectedInCents =>
      (details['expectedInCents'] as num?)?.toInt();

  @override
  List<Object?> get props => [refusal, details];
}
