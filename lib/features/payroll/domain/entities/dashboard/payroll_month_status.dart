/// L'état de la paie d'un mois, tel que le serveur le sert ; [none] quand
/// aucune écriture ne l'a encore ouverte.
enum PayrollMonthStatus {
  none('NONE'),
  draft('DRAFT'),
  submitted('SUBMITTED'),
  validated('VALIDATED');

  const PayrollMonthStatus(this.wire);
  final String wire;

  static PayrollMonthStatus fromWire(String? value) =>
      values.firstWhere((status) => status.wire == value, orElse: () => none);
}
