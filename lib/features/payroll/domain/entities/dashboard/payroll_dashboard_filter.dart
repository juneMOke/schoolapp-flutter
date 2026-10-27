/// Le statut d'une ligne « Ce que chaque salarié perçoit » : ceux de la
/// situation de paie (SP), servis par le serveur.
enum PayrollDashboardStatus {
  /// Paie non validée : rien ne se verse avant la validation.
  toDisburse('TO_DISBURSE'),

  /// Paie validée, rien de versé ce mois.
  due('DUE'),

  /// Paie validée, versée en partie.
  partial('PARTIAL'),

  /// Plus rien de dû, arriérés compris.
  settled('SETTLED');

  const PayrollDashboardStatus(this.wire);
  final String wire;

  static PayrollDashboardStatus fromWire(String? value) =>
      values.firstWhere((status) => status.wire == value, orElse: () => due);
}

/// Les filtres du tableau ; le fil est celui de la route JSON et de son PDF.
enum PayrollDashboardFilter {
  all('ALL', null),
  outstanding('OUTSTANDING', 'reste'),
  settled('SETTLED', 'soldes');

  const PayrollDashboardFilter(this.wire, this.address);
  final String wire;

  /// La valeur de l'adresse (`?filtre=`) ; `null` pour le défaut.
  final String? address;

  static PayrollDashboardFilter fromAddress(String? value) =>
      values.firstWhere((filter) => filter.address == value, orElse: () => all);
}
