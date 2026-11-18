import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tout handler d'outbox déclare le droit qu'exige sa poussée (ADR-014 §13.3).
///
/// Un handler qui l'oublie n'est pas pris par la pré-garde : un droit retiré
/// s'y découvre au serveur, et seule la sonde le rattrape. Ce test lit les
/// sources plutôt que la DI : il attrape aussi un handler pas encore
/// enregistré, au moment où il est écrit.
///
/// Les bases abstraites (`PayrollOutboxHandler`, `ChapitreChildOutboxHandler`)
/// déclarent pour leurs sous-classes : celles-ci n'apparaissent pas ici, leur
/// en-tête nomme la base et non `OutboxSyncHandler`.
void main() {
  test('chaque classe qui implémente OutboxSyncHandler implémente aussi '
      'OutboxWriteAccess', () {
    final header = RegExp(
      r'class\s+(\w+)(?:<[^>{]*>)?\s+([^{]*)\{',
      multiLine: true,
    );
    final missing = <String>[];
    var handlers = 0;

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart')) continue;
      final source = file.readAsStringSync();
      for (final m in header.allMatches(source)) {
        final clause = m.group(2)!;
        if (!RegExp(r'\bOutboxSyncHandler\b').hasMatch(clause)) continue;
        handlers++;
        if (!clause.contains('OutboxWriteAccess')) {
          missing.add('${file.path} : ${m.group(1)}');
        }
      }
    }

    // Garde-fou du test lui-même : une regex qui ne trouve plus rien
    // passerait au vert sans rien vérifier.
    expect(handlers, greaterThan(25));
    expect(missing, isEmpty, reason: 'Sans droit déclaré :\n$missing');
  });
}
