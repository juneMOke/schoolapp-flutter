import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_error_body_decoder.dart';

void main() {
  group('EditiqueErrorBodyDecoder.message', () {
    test('lit le message d un ApiError arrivé en octets', () {
      final bytes = Uint8List.fromList(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'timestamp': '2026-08-01T10:00:00Z',
            'status': 404,
            'error': 'Not Found',
            'message': "Aucune charge pour l'élève",
          }),
        ),
      );

      expect(
        EditiqueErrorBodyDecoder.message(bytes),
        "Aucune charge pour l'élève",
      );
    });

    test('accepte un corps déjà désérialisé en map', () {
      expect(
        EditiqueErrorBodyDecoder.message(<String, dynamic>{
          'message': 'Devises multiples',
        }),
        'Devises multiples',
      );
    });

    test('accepte un corps déjà décodé en chaîne', () {
      expect(
        EditiqueErrorBodyDecoder.message('{"message":"Validation failed"}'),
        'Validation failed',
      );
    });

    test('retombe sur error quand message est absent', () {
      expect(
        EditiqueErrorBodyDecoder.message('{"error":"Not Found"}'),
        'Not Found',
      );
    });

    test('ignore un message vide ou blanc et retombe sur error', () {
      expect(
        EditiqueErrorBodyDecoder.message(
          '{"message":"   ","error":"Conflict"}',
        ),
        'Conflict',
      );
    });

    test('rend null sans lever sur un corps qui n est pas du JSON', () {
      final pdf = Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D]);
      expect(EditiqueErrorBodyDecoder.message(pdf), isNull);
      expect(EditiqueErrorBodyDecoder.message('<html>oops</html>'), isNull);
    });

    test('rend null pour un corps vide, nul, ou un JSON non-objet', () {
      expect(EditiqueErrorBodyDecoder.message(null), isNull);
      expect(EditiqueErrorBodyDecoder.message(Uint8List(0)), isNull);
      expect(EditiqueErrorBodyDecoder.message('[1,2,3]'), isNull);
      expect(EditiqueErrorBodyDecoder.message('"juste une chaîne"'), isNull);
    });

    test('rend null sans lever sur des octets invalides en UTF-8', () {
      final invalid = Uint8List.fromList(<int>[0xC3, 0x28, 0xA0, 0xA1]);
      expect(EditiqueErrorBodyDecoder.message(invalid), isNull);
    });

    // Borne de sécurité : un PDF entier ne doit pas être décodé en chaîne.
    test('ne décode pas au-delà de la borne, sans lever', () {
      final huge = Uint8List(200 * 1024)..fillRange(0, 200 * 1024, 0x41);
      expect(EditiqueErrorBodyDecoder.message(huge), isNull);
    });
  });
}
