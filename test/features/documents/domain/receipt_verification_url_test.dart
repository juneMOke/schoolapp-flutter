import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/receipt_verification_url.dart';

/// Une URL qui ne s'imprime qu'en QR doit tomber à l'entrée quand elle est
/// douteuse : un QR se scanne avec la même confiance, qu'il mène chez le
/// serveur de l'école ou ailleurs.
void main() {
  test('une URL absolue https passe telle quelle', () {
    const url = 'https://api.eteelo.com/verify/RC/9f8e7d6c?t=abc';

    expect(ReceiptVerificationUrl.normalize(url), url);
    expect(
      ReceiptVerificationUrl.normalize('  https://verify.eteelo.com/v/1  '),
      'https://verify.eteelo.com/v/1',
    );
  });

  test('tout le reste vaut une absence, sans lever', () {
    for (final value in <Object?>[
      null,
      '',
      '   ',
      '/verify/RC/1',
      'ftp://api.eteelo.com/v/1',
      // En clair : détournable sur le réseau de celui qui scanne.
      'http://api.eteelo.com/v/1',
      // Se lit « eteelo », mène à `ailleurs.example`.
      'https://api.eteelo.com@ailleurs.example/verify/RC/1',
      'https://user:pw@api.eteelo.com/verify/RC/1',
      'javascript:alert(1)',
      'https://',
      42,
      'https://a.b/${'x' * 600}',
    ]) {
      expect(ReceiptVerificationUrl.normalize(value), isNull, reason: '$value');
    }
  });
}
