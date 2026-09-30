/// Les opérateurs de mobile money de la RDC, et leur forme sur le fil.
///
/// Dans le socle : la paie verse par eux aujourd'hui, la caisse les nommera
/// demain — deux listes finiraient par diverger.
enum MobileMoneyOperator {
  mpesa('MPESA'),
  orangeMoney('ORANGE_MONEY'),
  airtelMoney('AIRTEL_MONEY');

  const MobileMoneyOperator(this.wire);
  final String wire;

  /// L'opérateur portant [value], ou `null` (inconnu ou absent).
  static MobileMoneyOperator? fromWire(String? value) {
    for (final operator in values) {
      if (operator.wire == value) return operator;
    }
    return null;
  }
}
