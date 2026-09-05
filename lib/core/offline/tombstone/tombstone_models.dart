import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Pourquoi la ligne ne descendra plus. Les deux cas n'appellent pas la même
/// conduite, et c'est toute la raison de les distinguer d'un identifiant nu.
enum TombstoneReason {
  /// La ligne n'existe plus, pour personne. Retrait **inconditionnel**.
  deleted,

  /// La ligne existe toujours, mais a quitté le filtre du flux — un cours
  /// réaffecté, une préinscription convertie. Retrait **conditionnel** : seul
  /// l'ancien porteur efface, reconnu à ce que la ligne qu'il détient porte
  /// encore la portée annoncée. Sans cette condition, le nouveau porteur
  /// effacerait ce qu'il vient de recevoir.
  outOfScope,

  /// Motif inconnu de cette version du client. **Jamais appliqué** : effacer sur
  /// une règle qu'on ne connaît pas serait pire que de ne rien faire, et le
  /// serveur peut introduire un motif avant que le parc sache le traiter.
  unknown,
}

TombstoneReason _reasonOf(String? raw) => switch (raw) {
  'DELETED' => TombstoneReason.deleted,
  'OUT_OF_SCOPE' => TombstoneReason.outOfScope,
  _ => TombstoneReason.unknown,
};

/// Une disparition, telle qu'elle descend du serveur.
///
/// Quatre champs, et aucun champ métier : ni montant, ni nom. Un retrait descend
/// par un flux sans garde de permission, à des postes qui n'ont précisément plus
/// le droit de voir la donnée.
class TombstoneDto {
  /// La table locale visée, dans le vocabulaire du serveur (`kTombstoneTargets`).
  final String resource;

  /// La ligne à retirer. Pour `student_parent`, l'élève du couple.
  final String entityId;

  /// L'ancienne portée d'un retrait conditionnel. Pour `student_parent`, le
  /// parent du couple.
  final String? scopeKey;

  final TombstoneReason reason;

  const TombstoneDto({
    required this.resource,
    required this.entityId,
    required this.reason,
    this.scopeKey,
  });

  factory TombstoneDto.fromJson(Map<String, dynamic> j) => TombstoneDto(
    resource: j['resource'] as String,
    entityId: j['entityId'] as String,
    scopeKey: j['scopeKey'] as String?,
    reason: _reasonOf(j['reason'] as String?),
  );
}

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de figer le curseur. Même parti
/// que les autres pages keyset du client.
List<TombstoneDto> _lenientList(dynamic raw) {
  final out = <TombstoneDto>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(TombstoneDto.fromJson(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

/// Page keyset de retraits.
class TombstonePageDto implements KeysetPageDto<TombstoneDto> {
  @override
  final List<TombstoneDto> items;
  @override
  final KeysetPageEnvelope page;

  const TombstonePageDto({required this.items, required this.page});

  factory TombstonePageDto.fromJson(Map<String, dynamic> j) => TombstonePageDto(
    items: _lenientList(j['items']),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
