import 'package:cryptography/cryptography.dart';

/// Le condensat SHA-256 de [bytes], en **hexadécimal minuscule sur 64
/// caractères**.
///
/// Partagé, et c'est la raison de ce fichier. Deux implémentations de cet
/// encodage finiraient par diverger — une majuscule, un zéro de tête oublié —
/// et la divergence ne se verrait **pas** : elle ferait échouer une comparaison
/// d'empreintes en silence, ce qui se lit comme « le contenu a changé » et non
/// comme « nous comptons différemment ».
///
/// La forme est celle que le serveur emploie sur le fil : hex minuscule, sans
/// préfixe. Les deux côtés doivent pouvoir se comparer sans normaliser à chaque
/// lecture.
///
/// `cryptography` est déjà la bibliothèque de ce dépôt (`pubspec.yaml`), et son
/// API est asynchrone.
Future<String> sha256Hex(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  final buffer = StringBuffer();
  for (final byte in digest.bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
