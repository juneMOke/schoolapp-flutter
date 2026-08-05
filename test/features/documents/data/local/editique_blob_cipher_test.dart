import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_cipher.dart';

/// Le calcul seul : ce que le sceau garantit, et ce qu'il refuse.
void main() {
  // `compute` ouvre un vrai isolat — le liant doit exister avant.
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List key(int seed) =>
      Uint8List.fromList(List<int>.generate(32, (i) => (i + seed) & 0xFF));

  final pdf = Uint8List.fromList([
    ...'%PDF-1.4 reçu scellé'.codeUnits,
    ...List<int>.generate(300, (i) => i & 0xFF),
  ]);

  Future<EditiqueCipherResult> seal({
    Uint8List? bytes,
    Uint8List? secret,
    String entryId = 'c-1',
  }) => runEditiqueCipherTask(
    EditiqueCipherRequest(
      mode: EditiqueCipherMode.seal,
      keyBytes: secret ?? key(0),
      payload: bytes ?? pdf,
      entryId: entryId,
    ),
  );

  Future<EditiqueCipherResult> open(
    Uint8List file, {
    Uint8List? secret,
    String entryId = 'c-1',
  }) => runEditiqueCipherTask(
    EditiqueCipherRequest(
      mode: EditiqueCipherMode.open,
      keyBytes: secret ?? key(0),
      payload: file,
      entryId: entryId,
    ),
  );

  group('aller-retour', () {
    test('rend exactement les octets scellés', () async {
      final sealed = await seal();
      final opened = await open(sealed.bytes);

      expect(opened.bytes, equals(pdf));
      expect(opened.clearSizeBytes, pdf.length);
    });

    // RG-012-3 : la restitution doit être identique au bit près, et c'est
    // l'empreinte du CLAIR — jamais celle du fichier — qui l'atteste.
    test('rend la même empreinte au scellement et à l ouverture', () async {
      final sealed = await seal();
      final opened = await open(sealed.bytes);

      expect(opened.sha256Hex, sealed.sha256Hex);
      expect(sealed.sha256Hex, hasLength(64));
      expect(sealed.sha256Hex, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('l empreinte est bien celle du clair, pas celle du fichier', () async {
      final sealed = await seal();

      // Empreinte connue de la chaîne vide : la valeur ne se démontre pas
      // toute seule, elle se compare à une référence publiée.
      final empty = await seal(bytes: Uint8List(0));
      expect(
        empty.sha256Hex,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(sealed.sha256Hex, isNot(empty.sha256Hex));
    });

    test(
      'le surcoût du scellement est constant, quelle que soit la pièce',
      () async {
        final petit = await seal(bytes: Uint8List(10));
        final grand = await seal(bytes: Uint8List(100000));

        expect(petit.bytes.length - 10, 33);
        expect(grand.bytes.length - 100000, 33);
      },
    );

    // Deux scellements du même PDF ne doivent pas produire le même fichier :
    // le nonce est tiré à chaque fois, et un nonce réutilisé sous la même clé
    // casse AES-GCM.
    test(
      'deux scellements identiques produisent deux fichiers distincts',
      () async {
        final a = await seal();
        final b = await seal();

        expect(a.bytes, isNot(equals(b.bytes)));
        expect(a.sha256Hex, b.sha256Hex);
        expect(
          (await open(a.bytes)).bytes,
          equals((await open(b.bytes)).bytes),
        );
      },
    );
  });

  group('ce que le sceau refuse', () {
    test('une clé étrangère', () async {
      final sealed = await seal();

      expect(
        () => open(sealed.bytes, secret: key(1)),
        throwsA(isA<EditiqueCipherException>()),
      );
    });

    // Le fichier est nommé par l'identifiant de son entrée, et lié à lui : le
    // déplacer sur le nom d'une autre pièce le rend indéchiffrable. Sans cela,
    // l'index pourrait désigner des octets qui ne sont pas les siens.
    test('un fichier posé sous le nom d une autre entrée', () async {
      final sealed = await seal(entryId: 'c-1');

      expect(
        () => open(sealed.bytes, entryId: 'c-2'),
        throwsA(isA<EditiqueCipherException>()),
      );
    });

    test('un octet modifié dans le corps', () async {
      final sealed = await seal();
      final altered = Uint8List.fromList(sealed.bytes)..[40] ^= 0xFF;

      expect(() => open(altered), throwsA(isA<EditiqueCipherException>()));
    });

    test('un fichier tronqué', () async {
      final sealed = await seal();
      final tronque = Uint8List.sublistView(sealed.bytes, 0, 20);

      expect(() => open(tronque), throwsA(isA<EditiqueCipherException>()));
    });

    test('un fichier vide', () async {
      expect(() => open(Uint8List(0)), throwsA(isA<EditiqueCipherException>()));
    });

    // Un fichier étranger déposé dans le répertoire ne doit pas être pris pour
    // une pièce corrompue : la marque le distingue avant toute cryptographie.
    test('un fichier qui ne porte pas notre marque', () async {
      final etranger = Uint8List.fromList([
        ...'%PDF'.codeUnits,
        ...List<int>.filled(100, 0),
      ]);

      expect(() => open(etranger), throwsA(isA<EditiqueCipherException>()));
    });

    // L'octet de version est ce qui permettra de changer d'algorithme ou de
    // clé sans que les fichiers d'hier ne fassent tomber l'application : ils
    // se relisent comme un défaut de cache, et la pièce se retélécharge.
    test('une version de format inconnue', () async {
      final sealed = await seal();
      final futur = Uint8List.fromList(sealed.bytes)..[4] = 99;

      expect(() => open(futur), throwsA(isA<EditiqueCipherException>()));
    });

    test('une clé qui n a pas la bonne longueur', () async {
      expect(
        () => seal(secret: Uint8List(16)),
        throwsA(isA<EditiqueCipherException>()),
      );
    });
  });

  group('format', () {
    test('commence par la marque et la version', () async {
      final sealed = await seal();

      expect(
        sealed.bytes.sublist(0, kEditiqueBlobHeaderLength),
        equals([...kEditiqueBlobMagic, kEditiqueBlobFormatVersion]),
      );
    });

    // Le fichier ne doit rien laisser paraître du PDF qu'il contient.
    test('ne laisse pas transparaître le clair', () async {
      final sealed = await seal();
      final entete = String.fromCharCodes(
        sealed.bytes.sublist(kEditiqueBlobHeaderLength, 60),
      );

      expect(entete.contains('%PDF'), isFalse);
    });
  });

  // Le calcul est exécuté dans un isolat en production : une fermeture capturant
  // son contexte n'y survivrait pas. Ce test exerce le vrai chemin, pas la
  // fonction appelée en direct.
  group('traversée d isolat', () {
    test('scelle et rouvre à travers compute()', () async {
      final sealed = await offloadEditiqueCipher(
        EditiqueCipherRequest(
          mode: EditiqueCipherMode.seal,
          keyBytes: key(0),
          payload: pdf,
          entryId: 'c-1',
        ),
      );
      final opened = await offloadEditiqueCipher(
        EditiqueCipherRequest(
          mode: EditiqueCipherMode.open,
          keyBytes: key(0),
          payload: sealed.bytes,
          entryId: 'c-1',
        ),
      );

      expect(opened.bytes, equals(pdf));
      expect(opened.sha256Hex, sealed.sha256Hex);
    });

    test('remonte l échec d authentification depuis l isolat', () async {
      final sealed = await offloadEditiqueCipher(
        EditiqueCipherRequest(
          mode: EditiqueCipherMode.seal,
          keyBytes: key(0),
          payload: pdf,
          entryId: 'c-1',
        ),
      );

      expect(
        () => offloadEditiqueCipher(
          EditiqueCipherRequest(
            mode: EditiqueCipherMode.open,
            keyBytes: key(2),
            payload: sealed.bytes,
            entryId: 'c-1',
          ),
        ),
        throwsA(isA<EditiqueCipherException>()),
      );
    });
  });
}
