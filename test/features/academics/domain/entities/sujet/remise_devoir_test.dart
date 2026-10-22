import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/remise_devoir.dart';

void main() {
  test('par défaut : les valeurs du serveur (en classe, fin du jour)', () {
    expect(RemiseDevoir.parDefaut.toJson(), {
      'heureLimite': null,
      'modeRemise': 'EN_CLASSE',
      'depotTardifPermis': false,
    });
  });

  test('les trois champs partent toujours ensemble', () {
    const remise = RemiseDevoir(
      mode: ModeRemise.enLigne,
      heureLimite: '17:30',
      depotTardifPermis: true,
    );
    expect(remise.toJson(), {
      'heureLimite': '17:30',
      'modeRemise': 'EN_LIGNE',
      'depotTardifPermis': true,
    });
  });

  test('en classe, un dépôt tardif n a pas de sens et tombe', () {
    const remise = RemiseDevoir(depotTardifPermis: true);
    expect(remise.toJson()['depotTardifPermis'], isFalse);
  });

  test('une heure illisible revient à « fin du jour »', () {
    for (final heure in ['25:00', '7:30', 'midi', '']) {
      expect(RemiseDevoir(heureLimite: heure).normalized().heureLimite, isNull);
    }
    expect(
      const RemiseDevoir(heureLimite: '07:05').normalized().heureLimite,
      '07:05',
    );
  });

  test('lecture tolérante : champ absent ou inconnu → défaut', () {
    expect(RemiseDevoir.fromJson(const {}), RemiseDevoir.parDefaut);
    expect(
      RemiseDevoir.fromJson(const {'modeRemise': 'PAR_PIGEON'}).mode,
      ModeRemise.enClasse,
    );
  });

  test('copyWith retire l heure par une fonction qui rend null', () {
    const remise = RemiseDevoir(heureLimite: '17:30');
    expect(remise.copyWith(heureLimite: () => null).heureLimite, isNull);
    expect(remise.copyWith(mode: ModeRemise.enLigne).heureLimite, '17:30');
  });

  test('une heure avec secondes est ramenée à HH:mm, pas perdue', () {
    expect(
      const RemiseDevoir(heureLimite: '17:30:15').normalized().heureLimite,
      '17:30',
    );
  });
}
