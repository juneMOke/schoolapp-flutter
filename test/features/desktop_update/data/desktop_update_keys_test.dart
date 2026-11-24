import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

void main() {
  // La CI vérifie sa signature contre `scripts/release/public_keys/<canal>.b64` :
  // ces fichiers doivent être la clé que l'application embarque, sinon une
  // publication « verte » serait ignorée par tous les postes.
  for (final channel in ['staging', 'prod']) {
    test('la clé de la CI pour $channel est celle de l’application', () {
      final committed = File(
        'scripts/release/public_keys/$channel.b64',
      ).readAsStringSync().trim();
      expect(AppConstants.desktopUpdatePublicKeys[channel], [committed]);
    });
  }

  test('une clé de staging ne vaut pas pour la prod', () {
    final prod = AppConstants.desktopUpdatePublicKeys['prod']!;
    final staging = AppConstants.desktopUpdatePublicKeys['staging']!;
    expect(prod.toSet().intersection(staging.toSet()), isEmpty);
  });
}
