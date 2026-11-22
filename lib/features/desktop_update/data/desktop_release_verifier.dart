import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

/// Vérifie la fiche signée par la CI et en tire la [DesktopRelease].
///
/// Un poste n'installe que ce que la CI a produit : la signature Ed25519 porte
/// sur les octets UTF-8 EXACTS de `signedPayload`, qu'aucune couche ne
/// recompose. Chaque champ utile est lu DANS cette chaîne, jamais dans le
/// JSON d'à côté, puis confronté à ce que le poste attend (sa plateforme, son
/// canal, le dépôt des releases).
class DesktopReleaseVerifier {
  /// Clés publiques Ed25519 acceptées (32 octets, base64). Plusieurs, pour la
  /// rotation : une nouvelle clé est livrée une version avant de signer.
  final List<String> publicKeys;
  final DesktopPlatform platform;
  final String channel;

  DesktopReleaseVerifier({
    required this.platform,
    required this.channel,
    List<String>? publicKeys,
  }) : publicKeys = publicKeys ?? AppConstants.desktopUpdatePublicKeys;

  static final _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final _ed25519 = Ed25519();

  /// La version signée, ou une [FormatException] qui dit pourquoi non.
  Future<DesktopRelease> verify({
    required String signedPayload,
    required String signature,
  }) async {
    final List<int> signatureBytes;
    try {
      signatureBytes = base64.decode(signature.trim());
    } on FormatException {
      throw const FormatException('signature: base64 invalide');
    }
    if (signatureBytes.length != 64) {
      throw const FormatException('signature: 64 octets attendus');
    }
    final message = utf8.encode(signedPayload);
    if (!await _signedByKnownKey(message, signatureBytes)) {
      throw const FormatException('signature: aucune clé connue ne la valide');
    }
    return _parse(signedPayload);
  }

  Future<bool> _signedByKnownKey(List<int> message, List<int> sig) async {
    for (final encoded in publicKeys) {
      final List<int> key;
      try {
        key = base64.decode(encoded);
      } on FormatException {
        continue;
      }
      if (key.length != 32) continue;
      final ok = await _ed25519.verify(
        message,
        signature: Signature(
          sig,
          publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
        ),
      );
      if (ok) return true;
    }
    return false;
  }

  DesktopRelease _parse(String signedPayload) {
    final decoded = jsonDecode(signedPayload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('signedPayload: objet attendu');
    }
    String text(String key) {
      final value = decoded[key];
      if (value is! String) throw FormatException('$key: chaîne attendue');
      return value;
    }

    final payloadPlatform = text('platform');
    if (payloadPlatform != platform.wire) {
      throw FormatException(
        'platform: $payloadPlatform au lieu de ${platform.wire}',
      );
    }
    final payloadChannel = text('channel');
    if (payloadChannel != channel) {
      throw FormatException('channel: $payloadChannel au lieu de $channel');
    }
    final version = AppVersion.tryParseStrict(text('version'));
    if (version == null) throw const FormatException('version: X.Y.Z attendu');
    final sha256 = text('sha256');
    if (!_sha256.hasMatch(sha256)) {
      throw const FormatException(
        'sha256: 64 hexadécimaux minuscules attendus',
      );
    }
    final size = decoded['size'];
    if (size is! int || size <= 0) {
      throw const FormatException('size: entier positif attendu');
    }
    final url = Uri.tryParse(text('url'));
    if (url == null || !isAllowedDownloadUrl(url)) {
      throw const FormatException('url: hors du dépôt des releases');
    }
    return DesktopRelease(
      version: version,
      platform: platform,
      channel: channel,
      url: url,
      sha256: sha256,
      size: size,
      notesFr: text('notesFr'),
      notesEn: text('notesEn'),
    );
  }

  /// HTTPS, hôte et chemin des releases du dépôt, sans détour (`..`, port,
  /// identifiants, requête).
  static bool isAllowedDownloadUrl(Uri url) {
    final allowed = Uri.parse(AppConstants.desktopUpdateDownloadPrefix);
    return url.scheme == 'https' &&
        url.host == allowed.host &&
        !url.hasPort &&
        url.userInfo.isEmpty &&
        !url.hasQuery &&
        !url.hasFragment &&
        url.path.startsWith(allowed.path) &&
        !url.pathSegments.any((s) => s == '..' || s == '.' || s.isEmpty) &&
        // `…/download/<tag>/<fichier>` : exactement deux segments après le
        // préfixe.
        url.pathSegments.length ==
            allowed.pathSegments.where((s) => s.isNotEmpty).length + 2;
  }
}
