import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';

/// Fige, en valeurs **littérales**, ce que les caches éditiques déjà présents
/// sur les tablettes du parc exigent pour rester lisibles.
///
/// Les autres tests passent par les constantes : renommer l'une d'elles les
/// laisserait verts, alors que chaque tablette perdrait ses pièces — une clé
/// introuvable se régénère neuve, et une clé neuve efface le répertoire.
void main() {
  test('le cache éditique garde son répertoire et le nom de sa clé', () {
    expect(AppConstants.editiqueCacheDirectoryName, 'editique_cache');
    expect(AppConstants.editiqueCacheKeyStorageKey, 'editique_cache_key');
  });

  test('le format de fichier garde son en-tête ETLQ, version 1', () {
    expect(kBlobMagic, [0x45, 0x54, 0x4C, 0x51]);
    expect(kBlobFormatVersion, 1);
    expect(kBlobHeaderLength, 5);
  });
}
