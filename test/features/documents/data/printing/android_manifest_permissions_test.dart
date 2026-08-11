import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Épingle les permissions Bluetooth du manifeste Android.
///
/// ## Pourquoi un test lit un fichier XML
///
/// Aucune ligne de Dart ne voit les permissions : elles vivent dans le
/// manifeste, sont fusionnées par Gradle, et ne se manifestent qu'au moment où
/// une tablette refuse un appel natif. La panne est déjà arrivée —
/// `BLUETOOTH_SCAN` avait été retirée sur un raisonnement juste (« nous ne
/// découvrons jamais ») mais insuffisant : le plugin annule la découverte avant
/// d'ouvrir la liaison, et cet appel en relève. Résultat sur le terrain : une
/// `SecurityException` avalée par le `catch` du plugin, un flux `null`, et un
/// message « imprimante injoignable » qui désignait la mauvaise cause.
///
/// ⚠️ Portée réelle : ce test lit **notre** manifeste source, pas le manifeste
/// fusionné. Il attrape une régression de nos propres décisions ; il ne verrait
/// pas une permission injectée par la mise à jour d'un plugin.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  /// La déclaration entière d'une permission, attributs compris.
  String declarationOf(String permission) {
    final match = RegExp(
      '<uses-permission[^>]*android:name="android.permission.$permission"[^>]*/>',
      dotAll: true,
    ).firstMatch(manifest);
    expect(
      match,
      isNotNull,
      reason: '$permission absente du manifeste — voir la note de ce fichier.',
    );
    return match!.group(0)!;
  }

  test('BLUETOOTH_SCAN est déclarée : cancelDiscovery() en dépend', () {
    final scan = declarationOf('BLUETOOTH_SCAN');

    // Le retrait est précisément ce qui avait cassé l'impression.
    expect(scan, isNot(contains('tools:node="remove"')));
  });

  test('BLUETOOTH_SCAN promet de ne pas servir à localiser', () {
    final scan = declarationOf('BLUETOOTH_SCAN');

    // Sans ce drapeau, la permission traîne ACCESS_FINE_LOCATION derrière elle
    // dans l'esprit du Play Store — et le parc ETEELO ne peut pas le justifier.
    expect(scan, contains('android:usesPermissionFlags="neverForLocation"'));
  });

  test('BLUETOOTH_CONNECT est déclarée, sans borne de version', () {
    final connect = declarationOf('BLUETOOTH_CONNECT');

    // Elle n'existe qu'à partir d'Android 12 et vaut pour toutes les suivantes :
    // une `maxSdkVersion` ici rendrait l'impression impossible sur le parc récent.
    expect(connect, isNot(contains('maxSdkVersion')));
  });

  test('les permissions legacy s\'arrêtent à Android 11', () {
    for (final legacy in ['BLUETOOTH', 'BLUETOOTH_ADMIN']) {
      expect(
        declarationOf(legacy),
        contains('android:maxSdkVersion="30"'),
        reason:
            '$legacy est remplacée par BLUETOOTH_CONNECT dès Android 12 ; '
            'sans borne, elle serait demandée sur tout le parc.',
      );
    }
  });

  test('aucune permission de localisation', () {
    // L'application ne découvre jamais : elle lit `bondedDevices`. C'est ce qui
    // maintient la localisation hors du périmètre, et cet invariant-là tient.
    //
    // On inspecte les DÉCLARATIONS, pas le fichier entier : les commentaires du
    // manifeste nomment `ACCESS_FINE_LOCATION` pour expliquer justement pourquoi
    // elle n'est pas demandée. Une recherche naïve rougirait sur sa propre
    // justification.
    final declared = RegExp(
      r'<uses-permission[^>]*/>',
      dotAll: true,
    ).allMatches(manifest).map((match) => match.group(0)!);

    expect(
      declared.where((line) => line.contains('LOCATION')),
      isEmpty,
      reason: 'Une permission de localisation a été déclarée.',
    );
  });
}
