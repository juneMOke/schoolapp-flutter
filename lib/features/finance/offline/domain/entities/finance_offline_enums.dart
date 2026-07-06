/// Moyen de paiement (aligné back). Défaut CASH.
enum PaymentMethod {
  cash('CASH'),
  creditCard('CREDIT_CARD'),
  debitCard('DEBIT_CARD'),
  mobileMoney('MOBILE_MONEY');

  const PaymentMethod(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static PaymentMethod fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'CREDIT_CARD' => PaymentMethod.creditCard,
        'DEBIT_CARD' => PaymentMethod.debitCard,
        'MOBILE_MONEY' => PaymentMethod.mobileMoney,
        _ => PaymentMethod.cash,
      };
}

/// Codes de frais (`FeeCode`) — les 23 valeurs exactes du back. Défaut OTHER.
enum FeeCode {
  tuition('TUITION'),
  registration('REGISTRATION'),
  enrollment('ENROLLMENT'),
  application('APPLICATION'),
  admission('ADMISSION'),
  canteen('CANTEEN'),
  transport('TRANSPORT'),
  boarding('BOARDING'),
  books('BOOKS'),
  uniform('UNIFORM'),
  examination('EXAMINATION'),
  labFee('LAB_FEE'),
  activity('ACTIVITY'),
  sports('SPORTS'),
  library('LIBRARY'),
  technology('TECHNOLOGY'),
  development('DEVELOPMENT'),
  insurance('INSURANCE'),
  securityDeposit('SECURITY_DEPOSIT'),
  processingFee('PROCESSING_FEE'),
  latePaymentFee('LATE_PAYMENT_FEE'),
  refund('REFUND'),
  other('OTHER');

  const FeeCode(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static FeeCode fromApiValue(String? value) {
    final upper = value?.toUpperCase();
    for (final code in FeeCode.values) {
      if (code.apiValue == upper) return code;
    }
    return FeeCode.other;
  }
}

/// Verdict d'exigibilité local (affichage) — réplique de `ExigibiliteService`.
/// Le verdict autoritaire (arriéré exigible) reste serveur.
enum ChargeExigibilite {
  aVenir('A_VENIR'),
  echuSolde('ECHU_SOLDE'),
  echuPartiel('ECHU_PARTIEL'),
  echuImpaye('ECHU_IMPAYE');

  const ChargeExigibilite(this.apiValue);

  final String apiValue;
}
