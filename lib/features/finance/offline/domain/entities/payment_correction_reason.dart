/// Le geste posé sur un versement.
enum PaymentCorrectionGesture {
  /// Le versement n'aurait pas dû exister.
  cancel,

  /// Le versement existe, mais il est faux : il est annulé et remplacé.
  replace,
}

/// Motif d'une correction, en liste fermée (R6). Le code voyage sur le fil ;
/// la précision libre voyage à côté, dans `reason`.
enum PaymentCorrectionReason {
  refunded('REFUNDED', PaymentCorrectionGesture.cancel),
  duplicate('DUPLICATE', PaymentCorrectionGesture.cancel),
  wrongDevice('WRONG_DEVICE', PaymentCorrectionGesture.cancel),
  wrongAmount('WRONG_AMOUNT', PaymentCorrectionGesture.replace),
  wrongAllocation('WRONG_ALLOCATION', PaymentCorrectionGesture.replace),
  wrongStudent('WRONG_STUDENT', PaymentCorrectionGesture.replace),

  /// Valable pour les deux gestes ; la précision devient obligatoire.
  other('OTHER', null);

  const PaymentCorrectionReason(this.code, this._gesture);

  final String code;
  final PaymentCorrectionGesture? _gesture;

  /// Le motif a un sens pour ce geste. `WRONG_STUDENT` sans remplaçant, ou
  /// `DUPLICATE` avec un remplaçant, ne décrivent rien de réel.
  bool fits(PaymentCorrectionGesture gesture) =>
      _gesture == null || _gesture == gesture;

  bool get requiresDetail => this == PaymentCorrectionReason.other;

  /// Les motifs proposés pour un geste, dans l'ordre d'affichage.
  static List<PaymentCorrectionReason> forGesture(
    PaymentCorrectionGesture gesture,
  ) => values.where((r) => r.fits(gesture)).toList(growable: false);

  static PaymentCorrectionReason? fromCode(String? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}
