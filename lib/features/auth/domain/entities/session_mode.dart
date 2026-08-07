/// Mode de dégradation de la session offline (ADR-010 D-08).
///
/// - [normal] (J0–J7) : tout fonctionne.
/// - [warning] (J7–J21) : saisie + consultation OK, bandeau permanent,
///   scellement/impression de documents définitifs bloqués.
/// - [readOnly] (J21+ ou triche horloge) : lecture seule, reconnexion online
///   exigée.
enum SessionMode {
  normal('NORMAL'),
  warning('WARNING'),
  readOnly('READ_ONLY');

  const SessionMode(this.wire);

  /// Valeur persistée (`auth_local_session.degraded_mode`, contrainte CHECK).
  final String wire;

  static SessionMode fromWire(String? value) {
    return SessionMode.values.firstWhere(
      (m) => m.wire == value,
      orElse: () => SessionMode.normal,
    );
  }

  bool get blocksWrites => this == SessionMode.readOnly;

  /// Le scellement/impression de documents définitifs est bloqué dès WARNING.
  bool get blocksSealing => this != SessionMode.normal;
}
