import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';

void main() {
  test('laisse intact ce qui est déjà imprimable', () {
    const text = 'Complexe scolaire La Colombe — Ngaliema';
    expect(
      TicketCharset.printable('Institut Sacré-Élite, Kinshasa'),
      'Institut Sacré-Élite, Kinshasa',
    );
    // Le tiret cadratin, lui, n'est PAS du Latin-1.
    expect(
      TicketCharset.printable(text),
      'Complexe scolaire La Colombe - Ngaliema',
    );
  });

  // LE cas qui a motivé ce module : « Sacré-Cœur » est un nom d'établissement
  // banal en RDC, et le glyphe disparaissait sans que rien ne le signale.
  test('translittère la ligature œ au lieu de la perdre', () {
    expect(
      TicketCharset.printable('Institut Sacré-Cœur'),
      'Institut Sacré-Coeur',
    );
    expect(TicketCharset.printable('ŒUVRE'), 'OEUVRE');
  });

  test('ramène l\'apostrophe typographique à l\'apostrophe droite', () {
    expect(TicketCharset.printable('Institut d’Élite'), "Institut d'Élite");
    expect(TicketCharset.printable('“citation”'), '"citation"');
  });

  // Orthographes d'Afrique centrale : ces lettres vivent dans des noms propres.
  test('translittère le latin étendu', () {
    expect(TicketCharset.printable('Lɔkɔ Ngɛlɛ'), 'Loko Ngele');
    expect(TicketCharset.printable('Ŋanga'), 'Nanga');
    expect(TicketCharset.printable('Ǎmba'), 'Amba');
    expect(TicketCharset.printable('Đurić'), 'Duric');
  });

  // Ce qui n'a pas de translittération devient VISIBLE : un nom imprimé
  // « M?ller » se corrige, un nom imprimé « Mller » se croit juste.
  test('rend visible ce qu\'il ne sait pas translittérer', () {
    expect(TicketCharset.printable('Мбала'), '?????');
    expect(TicketCharset.printable('Prix 100 €'), 'Prix 100 EUR');
  });

  test('supprime les caractères de largeur nulle sans les marquer', () {
    expect(TicketCharset.printable('Mba​la'), 'Mbala');
  });

  test('ramène les espaces exotiques à une espace ordinaire', () {
    expect(TicketCharset.printable('100 000'), '100 000');
  });

  test('est idempotent', () {
    const source = 'Sacré-Cœur d’Élite — Мбала';
    final once = TicketCharset.printable(source);

    expect(TicketCharset.printable(once), once);
    expect(TicketCharset.isPrintable(once), isTrue);
  });

  // La garantie qui compte : quelle que soit l'entrée, la sortie tient dans le
  // jeu de caractères que la police du ticket sait rendre.
  test('toute sortie est du Latin-1', () {
    const sources = [
      'Sacré-Cœur',
      'Институт',
      '学校',
      'Ǎ Ǐ Ǒ Ǔ ǹ ǵ',
      'ﬁn ﬂeur',
      '№ 42 ‰ ™',
      'Ĳsselmeer',
    ];

    for (final source in sources) {
      expect(
        TicketCharset.isPrintable(TicketCharset.printable(source)),
        isTrue,
        reason: source,
      );
    }
  });
}
