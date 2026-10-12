/// Où en est un communiqué. Le statut ne bouge que par une route de geste
/// (`/schedule`, `/unschedule`, `/send`, `/cancel`) : `PUT` ne touche que le
/// contenu.
enum AnnouncementStatus {
  draft('DRAFT'),
  scheduled('SCHEDULED'),
  sent('SENT'),
  cancelled('CANCELLED'),

  /// Le planificateur a échoué trois fois ; `lastSendError` dit pourquoi.
  failed('FAILED');

  const AnnouncementStatus(this.wire);

  final String wire;

  /// `null` pour un statut que l'application ne connaît pas : la ligne est
  /// alors écartée plutôt que d'offrir des gestes au jugé.
  static AnnouncementStatus? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }

  /// Le contenu se modifie encore : brouillon, programmé (jusqu'à l'heure),
  /// ou échec repassé en brouillon.
  bool get isEditable => this == draft || this == scheduled;

  /// `/send` est accepté depuis ces statuts (dont « repasser Maintenant » sur
  /// un programmé, et le renvoi d'un échec).
  bool get canSend => this == draft || this == scheduled || this == failed;

  /// `/cancel` retire le communiqué de la liste, sans l'effacer.
  bool get canCancel => this == draft || this == scheduled || this == failed;
}
