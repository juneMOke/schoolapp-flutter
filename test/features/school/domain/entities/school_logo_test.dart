import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';

void main() {
  test('même empreinte → même sceau, sans parcourir les octets', () {
    // Deux contenus sous une même empreinte n'existent pas en pratique — le
    // tirage vérifie les octets contre elle. Ce cas n'est là que pour épingler
    // que l'égalité ne parcourt JAMAIS le PNG : Equatable le ferait élément
    // par élément, à chaque comparaison d'état.
    expect(
      SchoolLogo(sha256: 'sceau-1', bytes: Uint8List.fromList(const [1])),
      SchoolLogo(sha256: 'sceau-1', bytes: Uint8List.fromList(const [2])),
    );
  });

  test('empreinte différente → sceau différent, même à octets égaux', () {
    final bytes = Uint8List.fromList(const [1, 2, 3]);

    expect(
      SchoolLogo(sha256: 'sceau-1', bytes: bytes),
      isNot(SchoolLogo(sha256: 'sceau-2', bytes: bytes)),
    );
  });
}
