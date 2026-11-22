import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_verifier.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

import '../fixtures.dart';

void main() {
  DesktopReleaseVerifier verifier({
    DesktopPlatform platform = DesktopPlatform.windows,
    String channel = 'prod',
    List<String>? keys,
  }) => DesktopReleaseVerifier(
    platform: platform,
    channel: channel,
    publicKeys: keys ?? [testPublicKey],
  );

  test(
    'accepte une fiche signée par la CI (OpenSSL), accents compris',
    () async {
      final release = await verifier().verify(
        signedPayload: signedPayload,
        signature: signature,
      );
      expect(release.version, const AppVersion(1, 9, 0));
      expect(release.size, 61);
      expect(release.notesFr, startsWith('Réglages : élèves'));
      expect(
        release.fileName,
        'eteelo-connect-1.9.0-prod-windows-x64-setup.exe',
      );
    },
  );

  test('refuse une fiche modifiée d’un octet', () {
    expect(
      verifier().verify(signedPayload: tamperedPayload, signature: signature),
      throwsFormatException,
    );
  });

  test('refuse une signature d’une clé inconnue', () {
    expect(
      verifier(
        keys: ['A+lBnwmZ0JoLvcRpZ3qN46OC8C4yI3mdN0/Xns48c4Q='],
      ).verify(signedPayload: signedPayload, signature: signature),
      throwsFormatException,
    );
  });

  test('accepte si l’une des clés connues la valide (rotation)', () async {
    final release = await verifier(
      keys: [
        'pas-du-base64',
        'A+lBnwmZ0JoLvcRpZ3qN46OC8C4yI3mdN0/Xns48c4Q=',
        testPublicKey,
      ],
    ).verify(signedPayload: signedPayload, signature: signature);
    expect(release.version, const AppVersion(1, 9, 0));
  });

  test('refuse une autre plateforme ou un autre canal', () {
    expect(
      verifier(
        platform: DesktopPlatform.linux,
      ).verify(signedPayload: signedPayload, signature: signature),
      throwsFormatException,
    );
    expect(
      verifier(
        channel: 'staging',
      ).verify(signedPayload: signedPayload, signature: signature),
      throwsFormatException,
    );
  });

  test('refuse une signature mal formée', () {
    expect(
      verifier().verify(signedPayload: signedPayload, signature: 'AAAA'),
      throwsFormatException,
    );
  });

  group('lien de téléchargement', () {
    const base =
        'https://github.com/juneMOke/schoolapp-flutter/releases/download';
    bool allowed(String url) =>
        DesktopReleaseVerifier.isAllowedDownloadUrl(Uri.parse(url));

    test('les releases du dépôt seulement', () {
      expect(allowed('$base/desktop-prod-v1.9.0/setup.exe'), isTrue);
      expect(
        allowed(
          'http://github.com/juneMOke/schoolapp-flutter/releases/download/t/f',
        ),
        isFalse,
      );
      expect(
        allowed(
          'https://evil.example/juneMOke/schoolapp-flutter/releases/download/t/f',
        ),
        isFalse,
      );
      expect(
        allowed('https://github.com/autre/depot/releases/download/t/f'),
        isFalse,
      );
      expect(
        allowed(
          'https://github.com:8443/juneMOke/schoolapp-flutter/releases/download/t/f',
        ),
        isFalse,
      );
      expect(
        allowed(
          'https://x@github.com/juneMOke/schoolapp-flutter/releases/download/t/f',
        ),
        isFalse,
      );
      expect(allowed('$base/t/f?x=1'), isFalse);
      expect(allowed('$base/t/../../../../autre/f'), isFalse);
      expect(allowed('$base/f'), isFalse);
      expect(allowed('$base/t/sous/f'), isFalse);
    });
  });
}
