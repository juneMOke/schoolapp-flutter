import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';

/// Un brouillon à ouvrir à la prochaine arrivée sur Communiqués — posé par
/// « Utiliser » depuis le menu Modèles, **consommé une seule fois** : revenir
/// aux Communiqués par le menu ne doit pas rouvrir le modèle d'hier.
class PendingAnnouncementSeed {
  final OwnerScopedValue<AnnouncementContent?> _value;

  PendingAnnouncementSeed({required String? Function() owner})
    : _value = OwnerScopedValue<AnnouncementContent?>(null, owner: owner);

  void request(AnnouncementContent seed) => _value.value = seed;

  AnnouncementContent? take() {
    final seed = _value.value;
    _value.value = null;
    return seed;
  }
}
