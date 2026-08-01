import 'dart:convert';

/// Récupère le message d'erreur du serveur dans le corps d'une réponse partie
/// en `ResponseType.bytes`.
///
/// Deux couches perdent ce message sur le chemin nominal :
///  - la requête est déclarée binaire, donc Dio ne désérialise pas le JSON
///    d'erreur : `response.data` arrive en `List<int>` ;
///  - l'intercepteur global de `injection.dart` remplace `e.error` par une
///    `Failure` à message **constant** (`'Resource not found'`…).
///
/// Ce décodeur rend au repository de quoi reconstruire une `Failure` portant le
/// message réel (`ApiError.message`), sans jamais lever : un corps illisible
/// rend simplement `null` et l'appelant garde son message par défaut.
class EditiqueErrorBodyDecoder {
  const EditiqueErrorBodyDecoder._();

  /// Longueur maximale décodée. Un corps d'erreur légitime tient largement
  /// dedans ; au-delà, c'est un PDF ou une page HTML et le décoder ne sert à
  /// rien.
  static const int _maxDecodedBytes = 64 * 1024;

  /// Extrait `message` (repli : `error`) du corps [data], quelle que soit sa
  /// forme reçue : octets, chaîne, ou map déjà désérialisée.
  static String? message(Object? data) {
    final decoded = _asJson(data);
    if (decoded is! Map) return null;

    for (final key in const ['message', 'error']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static Object? _asJson(Object? data) {
    if (data is Map) return data;

    final text = _asText(data);
    if (text == null || text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static String? _asText(Object? data) {
    if (data is String) return data.trim();
    if (data is! List<int>) return null;
    if (data.isEmpty) return null;

    final bounded = data.length > _maxDecodedBytes
        ? data.sublist(0, _maxDecodedBytes)
        : data;
    // `allowMalformed` : le corps peut être n'importe quoi (un PDF tronqué,
    // une page d'erreur d'un proxy). On veut une chaîne, pas une exception.
    return utf8.decode(bounded, allowMalformed: true).trim();
  }
}
