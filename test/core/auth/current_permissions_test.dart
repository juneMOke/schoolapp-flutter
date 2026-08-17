import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';

/// Le **signal** de F9 : `CurrentPermissions` est le seul point que traversent
/// les six chemins qui alimentent l'ensemble effectif (login en ligne, login
/// hors ligne, restauration au démarrage, refresh, tick de fraîcheur, wipe).
/// C'est donc lui, et lui seul, qui sait dire « l'ensemble a réellement
/// changé » — ce qui déclenche la relecture du plan de synchronisation.
///
/// Ce que ces tests protègent tient en une asymétrie : sous F5, le plan est
/// l'autorité de pull. Un **faux positif** de changement coûte un GET
/// idempotent ; un **faux négatif** laisse un droit élargi sans effet jusqu'au
/// prochain login. Mais un faux positif *permanent* — parce que le serveur
/// permute l'ordre d'un refresh à l'autre, ou parce que `null` serait « différent
/// de tout » — laisserait le plan perpétuellement marqué à relire, donc
/// perpétuellement restrictif. Les deux erreurs sont donc bornées ici.
void main() {
  late CurrentPermissions permissions;
  late int notifications;
  late void Function() desabonner;

  setUp(() {
    permissions = CurrentPermissions();
    notifications = 0;
    desabonner = permissions.addChangeListener(() => notifications++);
  });

  tearDown(() => desabonner());

  group('set() — ne notifie que sur un changement réel', () {
    test('un ensemble différent notifie', () {
      permissions.set(const ['classroom.read']);

      expect(notifications, 1);
      expect(permissions.permissions, const ['classroom.read']);
    });

    test('le même ensemble, réémis, ne notifie pas', () {
      permissions.set(const ['classroom.read', 'finance.payment.read']);
      expect(notifications, 1);

      permissions.set(const ['classroom.read', 'finance.payment.read']);

      expect(notifications, 1);
    });

    test('l\'ordre ne compte pas : la comparaison est ENSEMBLISTE', () {
      // Rien ne fige l'ordre d'émission du serveur. Comparer en liste ferait
      // signaler un changement à chaque permutation, donc relire le plan à
      // chaque refresh — et sous F5, un plan perpétuellement « à relire »
      // restreint le pull au lieu d'être simplement en retard.
      permissions.set(const ['classroom.read', 'finance.payment.read']);
      expect(notifications, 1);

      permissions.set(const ['finance.payment.read', 'classroom.read']);

      expect(notifications, 1);
    });

    test('même taille, contenu différent : notifie', () {
      permissions.set(const ['classroom.read', 'finance.payment.read']);
      expect(notifications, 1);

      permissions.set(const ['classroom.read', 'discipline.read']);

      expect(notifications, 2);
    });

    test('un ensemble rétréci notifie', () {
      permissions.set(const ['classroom.read', 'finance.payment.read']);

      permissions.set(const ['classroom.read']);

      expect(notifications, 2);
    });

    test('l\'ensemble vide réémis ne notifie pas', () {
      // Liste vide = « aucun droit », une information stable : la réémettre
      // n'est pas un changement.
      permissions.set(const []);
      expect(notifications, 1);

      permissions.set(const []);

      expect(notifications, 1);
    });
  });

  group('tri-état — null n\'est pas « différent de tout »', () {
    test('null → null ne notifie pas', () {
      // Un backend qui n'émet pas encore le champ laisse l'ensemble à null
      // refresh après refresh. Le traiter comme un changement ferait relire le
      // plan en boucle, donc — sous F5 — restreindrait le pull en permanence.
      expect(permissions.permissions, isNull);

      permissions.set(null);
      permissions.set(null);

      expect(notifications, 0);
    });

    test('null → ensemble connu notifie', () {
      permissions.set(const ['classroom.read']);

      expect(notifications, 1);
    });

    test('null → ensemble VIDE notifie : « aucun droit » n\'est pas '
        '« je ne sais pas »', () {
      permissions.set(const []);

      expect(notifications, 1);
      expect(permissions.permissions, isEmpty);
    });

    test('ensemble connu → null notifie', () {
      permissions.set(const ['classroom.read']);
      expect(notifications, 1);

      permissions.set(null);

      expect(notifications, 2);
      expect(permissions.permissions, isNull);
    });
  });

  group('clear()', () {
    test('notifie quand l\'ensemble était connu', () {
      permissions.set(const ['classroom.read']);
      expect(notifications, 1);

      permissions.clear();

      expect(notifications, 2);
      expect(permissions.permissions, isNull);
    });

    test('notifie quand l\'ensemble connu était vide', () {
      permissions.set(const []);
      expect(notifications, 1);

      permissions.clear();

      expect(notifications, 2);
    });

    test('notifie MÊME si l\'ensemble était déjà inconnu — c\'est un événement '
        'de fin de session, pas une écriture d\'état', () {
      // Trouvé en revue, et c'était un vrai défaut. `clear()` passait par la
      // comparaison d'ensembles : sur un backend qui n'émet pas encore les
      // permissions, l'ensemble est DÉJÀ `null` au moment du wipe, donc rien ne
      // changeait, donc rien ne partait. Le plan de synchronisation du compte
      // qui s'en allait survivait au compte suivant — et sous F5 il ne décide
      // plus d'un affichage mais de ce que ce compte TIRE.
      //
      // Un signal de trop coûte une relecture de plan idempotente ; un signal
      // manquant coûte le périmètre de synchronisation de quelqu'un d'autre.
      permissions.clear();

      expect(notifications, 1);
    });
  });

  group('abonnement', () {
    test('le désabonnement rendu par addChangeListener fonctionne', () {
      permissions.set(const ['classroom.read']);
      expect(notifications, 1);

      desabonner();
      permissions.set(const ['finance.payment.read']);

      expect(notifications, 1);
    });

    test('un désabonnement rejoué ne casse rien', () {
      desabonner();
      desabonner();

      permissions.set(const ['classroom.read']);

      expect(notifications, 0);
    });

    test('plusieurs abonnés sont tous prévenus', () {
      var second = 0;
      final desabonnerSecond = permissions.addChangeListener(() => second++);
      addTearDown(desabonnerSecond);

      permissions.set(const ['classroom.read']);

      expect(notifications, 1);
      expect(second, 1);
    });

    test('un abonné qui LÈVE n\'empêche ni les autres d\'être prévenus ni '
        'l\'écriture d\'avoir eu lieu', () {
      // Le holder de plan est un abonné ; s'il levait, l'ensemble effectif ne
      // devrait pas rester non écrit — la session serait alors filtrée sur des
      // droits périmés.
      final desabonnerFrondeur = permissions.addChangeListener(
        () => throw StateError('abonné en panne'),
      );
      addTearDown(desabonnerFrondeur);
      var apres = 0;
      final desabonnerApres = permissions.addChangeListener(() => apres++);
      addTearDown(desabonnerApres);

      permissions.set(const ['classroom.read']);

      expect(notifications, 1, reason: 'l\'abonné antérieur est prévenu');
      expect(apres, 1, reason: 'l\'abonné postérieur aussi');
      expect(permissions.permissions, const ['classroom.read']);
    });

    test('un abonné qui se désabonne DEPUIS son propre rappel ne casse pas '
        'l\'itération', () {
      var frondeur = 0;
      var apres = 0;
      late void Function() desabonnerFrondeur;
      desabonnerFrondeur = permissions.addChangeListener(() {
        frondeur++;
        desabonnerFrondeur();
      });
      final desabonnerApres = permissions.addChangeListener(() => apres++);
      addTearDown(desabonnerApres);

      permissions.set(const ['classroom.read']);

      expect(frondeur, 1);
      expect(apres, 1, reason: 'l\'itération se poursuit après la mutation');

      permissions.set(const ['finance.payment.read']);

      expect(frondeur, 1, reason: 'désabonné, donc plus jamais rappelé');
      expect(apres, 2);
    });
  });

  group('la liste posée est défensive', () {
    test(
      'muter la liste source après set() ne change pas l\'ensemble tenu',
      () {
        final source = <String>['classroom.read'];
        permissions.set(source);

        source.add('finance.payment.read');

        expect(permissions.permissions, const ['classroom.read']);
      },
    );
  });
}
