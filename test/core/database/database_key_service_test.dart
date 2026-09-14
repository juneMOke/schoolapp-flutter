import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:uuid/uuid.dart';

/// Les clés SQLCipher, exercées sur le faux en mémoire du paquet
/// `flutter_secure_storage` — donc sur le vrai service, pas sur un double.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> stored;
  late DatabaseKeyService service;

  setUp(() {
    stored = <String, String>{};
    // Singleton statique de plateforme : à réarmer à chaque test.
    FlutterSecureStorage.setMockInitialValues(stored);
    service = const DatabaseKeyService(FlutterSecureStorage(), Uuid());
  });

  final hex64 = RegExp(r'^[0-9a-f]{64}$');

  test(
    'la clé de l appareil est générée une fois puis rendue telle quelle',
    () async {
      final first = await service.getOrCreateDeviceKey();
      final second = await service.getOrCreateDeviceKey();

      expect(first, matches(hex64));
      expect(second, first);
      expect(stored, contains(AppConstants.sqlCipherDeviceKeyStorageKey));
      // Jamais sous le nom de la clé héritée : l'appareil n'hérite de rien.
      expect(stored, isNot(contains(AppConstants.sqlCipherKeyStorageKey)));
    },
  );

  test('une clé PAR école, stable pour chacune', () async {
    final a1 = await service.getOrCreateSchoolKey('school-a');
    final b = await service.getOrCreateSchoolKey('school-b');
    final a2 = await service.getOrCreateSchoolKey('school-a');

    expect(a1, matches(hex64));
    expect(a2, a1);
    expect(b, isNot(a1));
    expect(
      stored.keys,
      containsAll([
        DatabaseKeyService.schoolKeyStorageKey('school-a'),
        DatabaseKeyService.schoolKeyStorageKey('school-b'),
      ]),
    );
  });

  test('pas de clé héritée sur un poste qui n en a jamais eu', () async {
    expect(await service.readLegacyKey(), isNull);
  });

  test('adopter transfère la valeur héritée à l école, qui ouvre alors le '
      'même fichier', () async {
    stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy-key';
    FlutterSecureStorage.setMockInitialValues(stored);

    await service.adoptLegacyKey('school-a');

    expect(await service.getOrCreateSchoolKey('school-a'), 'legacy-key');
  });

  test('adopter ÉCRASE une clé d école sans fichier : garder l ancienne '
      'rendrait le fichier adopté illisible', () async {
    await service.getOrCreateSchoolKey('school-a');
    stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy-key';
    FlutterSecureStorage.setMockInitialValues(stored);

    await service.adoptLegacyKey('school-a');

    expect(await service.getOrCreateSchoolKey('school-a'), 'legacy-key');
  });

  test('adopter sans clé héritée lève plutôt que de perdre l accès', () async {
    expect(() => service.adoptLegacyKey('school-a'), throwsStateError);
  });

  test('oublier la clé héritée ne touche pas celle de l école qui l a '
      'adoptée', () async {
    stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy-key';
    FlutterSecureStorage.setMockInitialValues(stored);
    await service.adoptLegacyKey('school-a');

    await service.forgetLegacyKey();

    expect(await service.readLegacyKey(), isNull);
    expect(await service.getOrCreateSchoolKey('school-a'), 'legacy-key');
  });
}
