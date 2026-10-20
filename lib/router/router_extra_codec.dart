import 'dart:collection';
import 'dart:convert';
import 'dart:math';

/// Garde les `extra` de navigation EN MÉMOIRE quand go_router sérialise sa
/// pile.
///
/// ## Pourquoi
///
/// Chaque fois que le routeur se rafraîchit (`refreshListenable` : statut de
/// session, permissions, contexte académique), go_router reconstruit ses pages
/// à partir de l'état qu'il a SÉRIALISÉ. Sans codec, un `extra` non
/// JSON-isable — tous nos `…Intent` — y est remplacé par `null`. La page se
/// reconstruit alors sans son contexte : « Contexte de détail indisponible »
/// sur la fiche de facturation, constaté le 27/09/2026 juste après une
/// correction de versement (la synchronisation avait rafraîchi les permissions).
///
/// ## Comment
///
/// L'`extra` est rangé dans un registre et remplacé, dans l'état sérialisé,
/// par un identifiant ; relire l'identifiant rend l'objet d'origine. Même objet,
/// même identifiant : le registre ne grossit pas à chaque rafraîchissement.
///
/// Chaque registre a son jeton de session, écrit à côté de l'identifiant :
/// après un F5, l'historique du navigateur garde les états de la session
/// d'avant, dont les identifiants recommencent à 0 dans le nouveau registre —
/// sans jeton, Précédent rouvrait une fiche avec l'`extra` d'un autre élève.
///
/// ⚠️ **Mémoire seulement.** Un redémarrage à froid (état restauré par le
/// système) retrouve un registre vide et rend `null` — exactement le
/// comportement d'avant, que les pages gèrent déjà (carte de contexte
/// indisponible). Le registre est borné : au-delà de [capacity], les plus
/// anciens sortent.
class InMemoryExtraCodec extends Codec<Object?, Object?> {
  InMemoryExtraCodec({this.capacity = 64, int? session})
    : _session = session ?? Random().nextInt(_sessionRange);

  /// Borne du jeton. Écrite en clair : `1 << 32` vaut 0 sur le web, où les
  /// décalages se font sur 32 bits — `nextInt(0)` levait au démarrage.
  static const int _sessionRange = 0x7FFFFFFF;

  final int capacity;
  final int _session;

  final LinkedHashMap<int, Object> _byId = LinkedHashMap<int, Object>();
  final Map<Object, int> _idOf = Map<Object, int>.identity();
  int _nextId = 0;

  static const String _key = 'inMemoryExtra';
  static const String _sessionKey = 'inMemoryExtraSession';

  Object? _encode(Object? extra) {
    if (extra == null) return null;
    final known = _idOf[extra];
    final id = known ?? _nextId++;
    // Réinsérer en queue : l'entrée devient la plus récente.
    _byId.remove(id);
    _byId[id] = extra;
    _idOf[extra] = id;
    while (_byId.length > capacity) {
      final oldest = _byId.keys.first;
      final evicted = _byId.remove(oldest);
      if (evicted != null) _idOf.remove(evicted);
    }
    return <String, Object?>{_key: id, _sessionKey: _session};
  }

  Object? _decode(Object? encoded) {
    if (encoded is! Map) return null;
    // Un état d'une autre session (avant F5) : son identifiant ne désigne
    // rien ici.
    if (encoded[_sessionKey] != _session) return null;
    final id = encoded[_key];
    if (id is! int) return null;
    return _byId[id];
  }

  @override
  Converter<Object?, Object?> get encoder => _Converter(_encode);

  @override
  Converter<Object?, Object?> get decoder => _Converter(_decode);
}

class _Converter extends Converter<Object?, Object?> {
  const _Converter(this._convert);

  final Object? Function(Object?) _convert;

  @override
  Object? convert(Object? input) => _convert(input);
}
