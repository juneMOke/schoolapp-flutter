/// Motif d'une désactivation — liste fermée, facultative (`null` = aucun motif).
///
/// La valeur sur le fil ne se renomme pas : elle est contrainte par un `CHECK`
/// serveur. Une valeur inconnue se lit comme absente plutôt que de faire lever
/// la lecture d'une période.
enum SuspensionReason {
  medical('MEDICAL'),
  family('FAMILY'),
  disciplinary('DISCIPLINARY'),
  prolongedAbsence('PROLONGED_ABSENCE'),
  other('OTHER');

  const SuspensionReason(this.wire);

  final String wire;

  static SuspensionReason? fromWire(String? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}
