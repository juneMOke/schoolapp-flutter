import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/legacy_database_split.dart';

LegacyAccount _account(String uid, String school, {int lastSeen = 1}) =>
    LegacyAccount(userId: uid, schoolId: school, lastServerSeenAt: lastSeen);

LegacyPendingWrite _writtenBy(String uid) =>
    LegacyPendingWrite(payload: jsonEncode({'authorId': uid}));

/// Qui adopte la base héritée (MULTI_ECOLE_PLAN.md §10.3). Une erreur ici ne
/// lève rien : elle range les écritures d'une école dans le fichier d'une
/// autre, où elles attendraient un auteur qui n'y viendra jamais.
void main() {
  test('tablette mono-école — tout le parc hors staging — : cette école', () {
    expect(
      designateLegacyOwner(
        accounts: [_account('uid-a1', 'A'), _account('uid-a2', 'A')],
        sessionUserId: null,
        pending: const [],
      ),
      'A',
    );
  });

  test('l argent d abord : l école des écritures en attente passe devant '
      'celle de la session', () {
    expect(
      designateLegacyOwner(
        accounts: [_account('uid-a', 'A'), _account('uid-b', 'B')],
        sessionUserId: 'uid-a',
        pending: [_writtenBy('uid-b')],
      ),
      'B',
    );
  });

  test('la colonne school_id de l outbox compte, auteur ou pas', () {
    expect(
      designateLegacyOwner(
        accounts: [_account('uid-a', 'A')],
        sessionUserId: 'uid-a',
        pending: const [LegacyPendingWrite(payload: '{}', schoolId: 'B')],
      ),
      'B',
    );
  });

  test('écritures de deux écoles : la session tranche si elle en est', () {
    expect(
      designateLegacyOwner(
        accounts: [
          _account('uid-a', 'A'),
          _account('uid-b', 'B'),
          _account('uid-c', 'C'),
        ],
        sessionUserId: 'uid-b',
        pending: [_writtenBy('uid-a'), _writtenBy('uid-b')],
      ),
      'B',
    );
  });

  test('écritures de deux écoles, session ailleurs : le compte vu le plus '
      'récemment PARMI elles', () {
    expect(
      designateLegacyOwner(
        accounts: [
          _account('uid-a', 'A', lastSeen: 10),
          _account('uid-b', 'B', lastSeen: 20),
          _account('uid-c', 'C', lastSeen: 99),
        ],
        sessionUserId: 'uid-c',
        pending: [_writtenBy('uid-a'), _writtenBy('uid-b')],
      ),
      'B',
    );
  });

  test('rien en attente, plusieurs écoles : la session', () {
    expect(
      designateLegacyOwner(
        accounts: [
          _account('uid-a', 'A', lastSeen: 99),
          _account('uid-b', 'B', lastSeen: 1),
        ],
        sessionUserId: 'uid-b',
        pending: const [],
      ),
      'B',
    );
  });

  test('rien en attente, aucune session : le compte vu le plus récemment', () {
    expect(
      designateLegacyOwner(
        accounts: [
          _account('uid-a', 'A', lastSeen: 5),
          _account('uid-b', 'B', lastSeen: 50),
        ],
        sessionUserId: null,
        pending: const [],
      ),
      'B',
    );
  });

  test('une écriture sans auteur connu ne désigne personne', () {
    expect(
      designateLegacyOwner(
        accounts: [_account('uid-a', 'A')],
        sessionUserId: null,
        pending: [
          const LegacyPendingWrite(payload: '{}'),
          _writtenBy('uid-inconnu'),
        ],
      ),
      'A',
    );
  });

  test('aucun compte : personne — la première école qui ouvre une session '
      'adoptera', () {
    expect(
      designateLegacyOwner(
        accounts: const [],
        sessionUserId: null,
        pending: const [LegacyPendingWrite(payload: '{}')],
      ),
      isNull,
    );
  });
}
