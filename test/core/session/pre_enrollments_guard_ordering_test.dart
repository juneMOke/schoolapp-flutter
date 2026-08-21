import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Épingle **l'ordre** entre la garde du vivier de préinscriptions et le cycle
/// de synchronisation d'ouverture de session.
///
/// ## Pourquoi un test lit du source
///
/// Ce que ce fichier protège n'a pas de surface observable. Les deux gestes
/// partaient en `unawaited`, l'un sous l'autre : le source *avait l'air*
/// ordonné, le commentaire l'affirmait, et rien ne l'était. Le reproduire dans
/// un test demanderait de faire s'entrelacer un cycle de pull réseau et deux
/// écritures SQLite dans la bonne fenêtre — un test qui échouerait une fois sur
/// mille et passerait le reste du temps ne protège rien.
///
/// Le dépôt a déjà ce genre de garde-fou là où la panne ne se voit qu'en
/// production : `android_manifest_permissions_test.dart` lit le manifeste.
/// Même intention ici.
///
/// ## Ce que l'entrelacement coûtait
///
/// La purge est en deux temps — vider `ref_pre_enrollments`, puis rembobiner le
/// curseur keyset. Un cycle de préinscriptions qui insère ses lignes juste
/// avant le premier temps et écrit son curseur juste après le second laisse une
/// table vide derrière un curseur avancé. Le serveur répond « rien de neuf »
/// indéfiniment, et cette table est depuis la bascule dure la **seule** source
/// d'amorçage d'un brouillon PRE : ces préinscriptions ne reviennent jamais.
///
/// ⚠️ Portée réelle : ce test lit le source, donc il attrape le retour du
/// motif fautif, pas une désynchronisation venue d'ailleurs. Si les noms
/// changent, il rougit — c'est voulu : quelqu'un doit alors relire l'ordre.
void main() {
  late String source;

  setUpAll(() {
    source = File('lib/main.dart').readAsStringSync();
  });

  test('le cycle de synchro n\'est jamais lancé sans attendre la garde', () {
    expect(
      source.contains('unawaited(_syncStatusCubit.syncOnLogin())'),
      isFalse,
      reason:
          'lancé sans attente à côté de la garde, le cycle s\'entrelace avec '
          'la purge du vivier — table vidée derrière un curseur avancé, et les '
          'préinscriptions perdues pour de bon',
    );
  });

  test('la garde précède le cycle dans la même séquence', () {
    final guard = source.indexOf('await _guardPreEnrollmentsSchool();');
    final sync = source.indexOf('await _syncStatusCubit.syncOnLogin();');

    expect(guard, isNot(-1), reason: 'la garde n\'est plus appelée du tout');
    expect(sync, isNot(-1), reason: 'le cycle d\'ouverture a disparu');
    expect(
      guard,
      lessThan(sync),
      reason: 'l\'ordre est le correctif : purger, puis seulement tirer',
    );
  });

  test(
    'l\'ouverture de session déclenche bien la séquence, une seule fois',
    () {
      expect(
        source.contains('unawaited(_guardPreEnrollmentsSchoolThenSync());'),
        isTrue,
        reason:
            'la paire reste en `unawaited` — la porte de navigation ne doit '
            'attendre ni le disque ni le réseau — mais elle part comme UNE '
            'séquence',
      );
      expect(
        'await _syncStatusCubit.syncOnLogin();'.allMatches(source).length,
        1,
        reason:
            'deux appels au cycle rouvriraient la course par une autre porte',
      );
    },
  );
}
