import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

/// La garde lue depuis la base locale — fail-closed par construction.
void main() {
  late Database db;
  late LocalEditiqueCacheAccess access;

  setUp(() async {
    db = await openFullOfflineDb();
    access = LocalEditiqueCacheAccess(AuthLocalDao(db));
  });

  tearDown(() async => db.close());

  Future<void> seedSession(String role) async {
    await db.insert('auth_local_user', {
      'user_id': 'u-1',
      'email': 'agent@ecole.cd',
      'first_name': 'Amina',
      'last_name': 'Mbala',
      'role': role,
      'school_id': 'school-1',
      'password_verifier': 'v',
      'verifier_salt': 's',
      'user_version': 1,
      'first_online_login_at': 0,
      'last_server_seen_at': 0,
    });
    await db.insert('auth_local_session', {
      'id': 1,
      'user_id': 'u-1',
      'refresh_expires_at': 0,
      'last_evaluated_at': 0,
    });
  }

  test('un profil interne a droit au cache', () async {
    await seedSession('SECRETARY');

    expect(await access.isEntitled(), isTrue);
  });

  test('un enseignant ne l a pas', () async {
    await seedSession('TEACHER');

    expect(await access.isEntitled(), isFalse);
  });

  // Le point qui rend cette source PRÉFÉRABLE au secure storage : l'absence de
  // ligne se lit `null`, et `null` est un refus. Le secure storage, lui, rend
  // une chaîne vide — indiscernable d'un rôle sans droit seulement si la garde
  // est une liste blanche.
  test('aucune session ouverte vaut refus', () async {
    expect(await access.isEntitled(), isFalse);
  });

  test('une base illisible vaut refus', () async {
    await db.close();

    expect(await access.isEntitled(), isFalse);
  });
}
