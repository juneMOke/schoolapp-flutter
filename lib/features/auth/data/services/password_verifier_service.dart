import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Vérificateur de mot de passe **offline** (ADR-010 D-02).
///
/// Au premier login online (et à chaque login online, pour suivre un changement
/// de mot de passe), on calcule `Argon2id(password, salt)` et on le stocke en
/// `auth_local_user`. Le hash serveur ne descend **jamais** sur la tablette.
///
/// Ce vérificateur **ne déchiffre rien** : il répond uniquement « ce mot de passe
/// est-il correct ? » hors réseau. Le calcul tourne dans un **isolate**
/// ([compute]) pour ne pas geler l'UI.
class PasswordVerifierService {
  const PasswordVerifierService();

  /// Génère un salt aléatoire (16 octets) encodé base64.
  String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }

  /// Calcule le vérificateur pour [password] + [saltBase64] (base64). Retourne
  /// le hash encodé base64. Exécuté dans un isolate.
  Future<String> computeVerifier({
    required String password,
    required String saltBase64,
  }) {
    return compute(
      _deriveArgon2id,
      _Argon2Params(password: password, saltBase64: saltBase64),
    );
  }

  /// Vérifie [password] contre un [expectedVerifier] (base64) et son [saltBase64].
  /// Comparaison à **temps constant** (anti timing-attack, défense en profondeur).
  Future<bool> verify({
    required String password,
    required String saltBase64,
    required String expectedVerifier,
  }) async {
    final actual = await computeVerifier(
      password: password,
      saltBase64: saltBase64,
    );
    return _constantTimeEquals(actual, expectedVerifier);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// Paramètres Argon2id (ADR-010 D-02). Calibrés « modérés » pour tenir sur
/// tablette d'entrée de gamme sans geler (calcul en isolate) — à ré-évaluer sur
/// le parc réel (§8 du plan).
class _Argon2Params {
  final String password;
  final String saltBase64;

  const _Argon2Params({required this.password, required this.saltBase64});
}

/// Fonction top-level exécutée dans l'isolate par [compute].
Future<String> _deriveArgon2id(_Argon2Params params) async {
  final algorithm = Argon2id(
    parallelism: 1,
    memory: 8192, // blocs de 1 KiB ≈ 8 MiB
    iterations: 2,
    hashLength: 32,
  );
  final secretKey = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(params.password)),
    nonce: base64Decode(params.saltBase64),
  );
  final bytes = await secretKey.extractBytes();
  return base64Encode(bytes);
}
