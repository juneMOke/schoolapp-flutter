import 'dart:collection';
import 'dart:convert';

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
/// ⚠️ **Mémoire seulement.** Un redémarrage à froid (état restauré par le
/// système) retrouve un registre vide et rend `null` — exactement le
/// comportement d'avant, que les pages gèrent déjà (carte de contexte
/// indisponible). Le registre est borné : au-delà de [capacity], les plus
/// anciens sortent.
class InMemoryExtraCodec extends Codec<Object?, Object?> {
  InMemoryExtraCodec({this.capacity = 64});

  final int capacity;

  final LinkedHashMap<int, Object> _byId = LinkedHashMap<int, Object>();
  final Map<Object, int> _idOf = Map<Object, int>.identity();
  int _nextId = 0;

  static const String _key = 'inMemoryExtra';

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
    return <String, Object?>{_key: id};
  }

  Object? _decode(Object? encoded) {
    if (encoded is! Map) return null;
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
