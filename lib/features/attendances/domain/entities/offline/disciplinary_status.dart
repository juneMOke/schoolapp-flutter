/// Statut d'un cas disciplinaire côté **offline** (DF-1), figé client.
///
/// ⚠️ Distinct de [DisciplinaryCaseStatus] (online, open/inProgress/closed) : la
/// spec offline fige l'ensemble exact du contrat back miroir
/// `{OPEN, RESOLVED, PENDING, DISMISSED, UNKNOWN}` (régime C, traitement LWW).
enum DisciplinaryStatus {
  open('OPEN'),
  resolved('RESOLVED'),
  pending('PENDING'),
  dismissed('DISMISSED'),
  unknown('UNKNOWN');

  const DisciplinaryStatus(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static DisciplinaryStatus fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'OPEN' => DisciplinaryStatus.open,
        'RESOLVED' => DisciplinaryStatus.resolved,
        'PENDING' => DisciplinaryStatus.pending,
        'DISMISSED' => DisciplinaryStatus.dismissed,
        _ => DisciplinaryStatus.unknown,
      };

  /// Statut terminal (traitement clôturé).
  bool get isTerminal =>
      this == DisciplinaryStatus.resolved ||
      this == DisciplinaryStatus.dismissed;
}
