import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';

/// La clé du magasin d'octets, exercée sur le faux en mémoire du paquet
/// `flutter_secure_storage` — donc sur le vrai service, pas sur un double.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> stored;
  late BlobKeyService service;

  setUp(() {
    stored = <String, String>{};
    // Le faux est un singleton statique de plateforme : il faut le réarmer à
    // chaque test, sinon les clés fuient de l'un à l'autre.
    FlutterSecureStorage.setMockInitialValues(stored);
    service = const BlobKeyService(
      FlutterSecureStorage(),
      storageKey: AppConstants.editiqueCacheKeyStorageKey,
    );
  });

  test('génère une clé de 256 bits au premier besoin', () async {
    final key = await service.getOrCreate();

    expect(key.bytes, hasLength(32));
    expect(key.createdNow, isTrue);
    expect(stored, contains(AppConstants.editiqueCacheKeyStorageKey));
  });

  test('rend la même clé aux appels suivants', () async {
    final first = await service.getOrCreate();
    final second = await service.getOrCreate();

    expect(second.bytes, equals(first.bytes));
    expect(second.createdNow, isFalse);
  });

  // La clé du cache ne doit pas être celle de la base : détruire l'une ne doit
  // rien faire à l'autre (D-7).
  test('ne partage pas l entrée de la clé SQLCipher', () async {
    await service.getOrCreate();

    expect(stored, isNot(contains(AppConstants.sqlCipherKeyStorageKey)));
  });

  test('deux clés successives ne se ressemblent pas', () async {
    final first = await service.getOrCreate();
    await service.destroy();
    final second = await service.getOrCreate();

    expect(second.bytes, isNot(equals(first.bytes)));
    expect(second.createdNow, isTrue);
  });

  test('destroy efface l entrée', () async {
    await service.getOrCreate();
    await service.destroy();

    expect(stored, isNot(contains(AppConstants.editiqueCacheKeyStorageKey)));
  });

  // Le cas réel : une restauration de sauvegarde Android rapporte les fichiers
  // sans les préférences chiffrées, ou les rapporte corrompues. Échouer
  // laisserait le cache définitivement inutilisable ; on regénère, et
  // `createdNow` dira au magasin d'effacer les octets devenus illisibles.
  test('traite une valeur illisible comme une clé absente', () async {
    stored[AppConstants.editiqueCacheKeyStorageKey] = 'pas du base64 ###';

    final key = await service.getOrCreate();

    expect(key.bytes, hasLength(32));
    expect(key.createdNow, isTrue);
  });

  test('traite une clé de mauvaise longueur comme une clé absente', () async {
    stored[AppConstants.editiqueCacheKeyStorageKey] = base64Encode(
      List<int>.filled(16, 7),
    );

    final key = await service.getOrCreate();

    expect(key.bytes, hasLength(32));
    expect(key.createdNow, isTrue);
  });

  test('une clé vide compte pour absente', () async {
    stored[AppConstants.editiqueCacheKeyStorageKey] = '';

    expect((await service.getOrCreate()).createdNow, isTrue);
  });

  // Persistance réelle : un second service, comme un second lancement de
  // l'application, retrouve la clé du premier.
  test('la clé survit à la reconstruction du service', () async {
    final first = await service.getOrCreate();
    const other = BlobKeyService(
      FlutterSecureStorage(),
      storageKey: AppConstants.editiqueCacheKeyStorageKey,
    );

    final second = await other.getOrCreate();

    expect(second.bytes, equals(first.bytes));
    expect(second.createdNow, isFalse);
  });

  // Chaque magasin a sa clé : détruire celle de l'un ne doit rien rendre
  // illisible chez l'autre.
  test('deux noms de stockage, deux clés indépendantes', () async {
    const other = BlobKeyService(
      FlutterSecureStorage(),
      storageKey: 'autre_magasin_key',
    );

    final first = await service.getOrCreate();
    final second = await other.getOrCreate();
    await other.destroy();

    expect(second.bytes, isNot(equals(first.bytes)));
    expect(stored.keys, contains(AppConstants.editiqueCacheKeyStorageKey));
    expect(stored.keys, isNot(contains('autre_magasin_key')));
    expect((await service.getOrCreate()).createdNow, isFalse);
  });
}
