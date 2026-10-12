/// Un canal de diffusion. WhatsApp seul en V1 ; le contrat garde une liste
/// pour accueillir le portail parent sans rupture.
enum AnnouncementChannel {
  whatsapp('WHATSAPP');

  const AnnouncementChannel(this.wire);

  final String wire;

  /// `null` pour un canal inconnu de l'application : il est ignoré.
  static AnnouncementChannel? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}
