import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';

void main() {
  group('ContentDispositionParser.fileName', () {
    test('lit la forme entre guillemets posée par le serveur', () {
      expect(
        ContentDispositionParser.fileName(
          'attachment; filename="ETL-AI-2526-000087.pdf"',
        ),
        'ETL-AI-2526-000087.pdf',
      );
    });

    test('lit la forme sans guillemets', () {
      expect(
        ContentDispositionParser.fileName('attachment; filename=ETL-RC-01.pdf'),
        'ETL-RC-01.pdf',
      );
    });

    test('accepte inline autant qu attachment', () {
      expect(
        ContentDispositionParser.fileName('inline; filename="ETL-BU-99.pdf"'),
        'ETL-BU-99.pdf',
      );
    });

    test('préfère la forme étendue RFC 5987 quand les deux sont présentes', () {
      expect(
        ContentDispositionParser.fileName(
          "attachment; filename=\"repli.pdf\"; filename*=UTF-8''ETL%2DQT%2D2526.pdf",
        ),
        'ETL-QT-2526.pdf',
      );
    });

    test('ignore un charset non prévu par le RFC et retombe sur filename', () {
      expect(
        ContentDispositionParser.fileName(
          "attachment; filename=\"repli.pdf\"; filename*=SHIFT-JIS''x.pdf",
        ),
        'repli.pdf',
      );
    });

    test('rend null quand l en-tête est absent ou vide', () {
      expect(ContentDispositionParser.fileName(null), isNull);
      expect(ContentDispositionParser.fileName(''), isNull);
    });

    test('rend null quand aucun filename n est exploitable', () {
      expect(ContentDispositionParser.fileName('attachment'), isNull);
      expect(
        ContentDispositionParser.fileName('attachment; filename=""'),
        isNull,
      );
    });

    // Le nom vient du serveur et servira un jour à écrire un fichier : il ne
    // doit jamais pouvoir désigner un autre dossier.
    test('ne garde que le dernier segment d un chemin', () {
      expect(
        ContentDispositionParser.fileName(
          'attachment; filename="../../etc/passwd"',
        ),
        'passwd',
      );
      expect(
        ContentDispositionParser.fileName(
          r'attachment; filename="..\..\windows\system32\a.pdf"',
        ),
        'a.pdf',
      );
    });

    test('rend null pour un nom qui se réduit à un segment de navigation', () {
      expect(
        ContentDispositionParser.fileName('attachment; filename=".."'),
        isNull,
      );
      expect(
        ContentDispositionParser.fileName('attachment; filename="/"'),
        isNull,
      );
    });

    test('borne un nom démesuré', () {
      final long = 'a' * 500;
      final parsed = ContentDispositionParser.fileName(
        'attachment; filename="$long.pdf"',
      );
      expect(parsed, isNotNull);
      expect(parsed!.length, lessThanOrEqualTo(180));
    });
  });

  group('ContentDispositionParser.documentNumber', () {
    test('retire l extension pdf', () {
      expect(
        ContentDispositionParser.documentNumber('ETL-AI-2526-000087.pdf'),
        'ETL-AI-2526-000087',
      );
    });

    test('accepte une extension en majuscules', () {
      expect(
        ContentDispositionParser.documentNumber('ETL-NP-2526-000012.PDF'),
        'ETL-NP-2526-000012',
      );
    });

    test('accepte un nom sans extension', () {
      expect(
        ContentDispositionParser.documentNumber('ETL-QT-2526-000001'),
        'ETL-QT-2526-000001',
      );
    });

    test('rend null pour une entrée vide ou nulle', () {
      expect(ContentDispositionParser.documentNumber(null), isNull);
      expect(ContentDispositionParser.documentNumber('.pdf'), isNull);
    });

    test('rend null pour un nom qui ne ressemble pas à un numéro de pièce', () {
      expect(ContentDispositionParser.documentNumber('document.pdf'), isNull);
    });
  });
}
