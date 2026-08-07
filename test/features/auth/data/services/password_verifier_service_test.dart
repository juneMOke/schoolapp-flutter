import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/services/password_verifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = PasswordVerifierService();

  test('generateSalt produit un salt base64 non vide et distinct', () {
    final a = service.generateSalt();
    final b = service.generateSalt();
    expect(a, isNotEmpty);
    expect(a, isNot(equals(b)));
  });

  test(
    'computeVerifier est déterministe pour (password, salt) identiques',
    () async {
      final salt = service.generateSalt();
      final h1 = await service.computeVerifier(
        password: 'Motdepasse123',
        saltBase64: salt,
      );
      final h2 = await service.computeVerifier(
        password: 'Motdepasse123',
        saltBase64: salt,
      );
      expect(h1, equals(h2));
    },
  );

  test(
    'verify réussit pour le bon mot de passe, échoue pour un autre',
    () async {
      final salt = service.generateSalt();
      final verifier = await service.computeVerifier(
        password: 'Motdepasse123',
        saltBase64: salt,
      );

      expect(
        await service.verify(
          password: 'Motdepasse123',
          saltBase64: salt,
          expectedVerifier: verifier,
        ),
        isTrue,
      );
      expect(
        await service.verify(
          password: 'MauvaisMotDePasse',
          saltBase64: salt,
          expectedVerifier: verifier,
        ),
        isFalse,
      );
    },
  );
}
