import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';

void main() {
  test('variables connues, dans l\'ordre de l\'énumération', () {
    expect(
      AnnouncementVariables.usedIn('{montant} dû pour {eleve} ({eleve})'),
      {AnnouncementVariable.student, AnnouncementVariable.amount},
    );
  });

  test('accolades inconnues, sans doublon ; les crochets passent', () {
    expect(
      AnnouncementVariables.unknownIn('{date} à [lieu], {date} et {} {eleve}'),
      ['{date}', '{}'],
    );
  });

  test('insérer au curseur remplace la sélection', () {
    final inserted = AnnouncementVariables.insert(
      'Bonjour X !',
      AnnouncementVariable.student,
      start: 8,
      end: 9,
    );
    expect(inserted.text, 'Bonjour {eleve} !');
    expect(inserted.cursor, 15);
  });

  test('sans sélection valide, en fin de texte', () {
    final inserted = AnnouncementVariables.insert(
      'Bonjour ',
      AnnouncementVariable.classroom,
      start: -1,
      end: -1,
    );
    expect(inserted.text, 'Bonjour {classe}');
    expect(inserted.cursor, 16);
  });

  test('rendu : une variable sans valeur reste écrite', () {
    expect(
      AnnouncementVariables.render('{eleve} — {classe} — {x}', {
        AnnouncementVariable.student: 'Grâce KABONGO',
      }),
      'Grâce KABONGO — {classe} — {x}',
    );
  });
}
