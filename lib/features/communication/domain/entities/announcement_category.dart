/// La catégorie d'un communiqué : elle teinte la ligne, le médaillon et
/// l'aperçu, et se lit en capitales dans le message WhatsApp.
enum AnnouncementCategory {
  info('INFO'),
  urgent('URGENT'),
  event('EVENT'),
  administrative('ADMINISTRATIVE');

  const AnnouncementCategory(this.wire);

  /// La valeur sur le fil.
  final String wire;

  /// Une catégorie inconnue retombe sur [info] : la catégorie ne fait que
  /// teinter, elle ne décide d'aucun geste.
  static AnnouncementCategory fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return AnnouncementCategory.info;
  }
}
