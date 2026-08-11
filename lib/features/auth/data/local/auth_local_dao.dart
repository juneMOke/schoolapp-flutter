import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_models.dart';
import 'package:school_app_flutter/features/auth/data/session_permissions.dart';

/// Accès aux tables `auth_local` (ADR-010 §5) : profil vu online, vérificateur,
/// session locale et garde d'horloge. Purement stockage — la politique (fraîcheur,
/// révocation, ordre flush-avant-wipe) vit dans les couches supérieures.
///
/// **Invariant de wipe (D-09/D-11)** : [wipeSession] efface la session et
/// détache le `session_started_at` de l'utilisateur, mais **jamais**
/// [auth_local_user] (invariant « vu sur ce device », D-01) ni l'outbox.
class AuthLocalDao {
  final DatabaseExecutor _db;

  const AuthLocalDao(this._db);

  static const String userTable = 'auth_local_user';
  static const String sessionTable = 'auth_local_session';

  // ── auth_local_user ────────────────────────────────────────────────────────

  /// Insère ou met à jour l'enregistrement utilisateur (login online). Le
  /// vérificateur et `user_version` sont réécrits à chaque login online — ils
  /// suivent un éventuel changement de mot de passe / de rôle serveur.
  Future<void> upsertUser(AuthLocalUserRecord user) async {
    await _db.insert(
      userTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AuthLocalUserRecord?> getUserByEmail(String email) async {
    final rows = await _db.query(
      userTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuthLocalUserRecord.fromMap(rows.first);
  }

  Future<AuthLocalUserRecord?> getUser(String userId) async {
    final rows = await _db.query(
      userTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuthLocalUserRecord.fromMap(rows.first);
  }

  /// Utilisateur de la session courante (join `auth_local_session` → user), ou
  /// null si aucune session active.
  Future<AuthLocalUserRecord?> getSessionUser() async {
    final session = await getSession();
    if (session == null) return null;
    return getUser(session.userId);
  }

  /// Avance l'ancre temporelle serveur (D-07). `ms` = header `Date` du serveur,
  /// jamais l'horloge device.
  Future<void> updateLastServerSeen(String userId, int ms) async {
    await _db.update(
      userTable,
      {'last_server_seen_at': ms},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Met à jour la valeur de révocation connue localement (login/refresh).
  Future<void> updateUserVersion(String userId, int version) async {
    await _db.update(
      userTable,
      {'user_version': version},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Avance la borne offline par utilisateur (amendement m4) : posée à chaque
  /// contact online porteur d'une borne refresh (login online, refresh rotatif).
  /// Jamais appelée offline — le temps ne peut que dégrader (D-08).
  Future<void> updateRefreshExpiresAt(String userId, int ms) async {
    await _db.update(
      userTable,
      {'refresh_expires_at': ms},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Réécrit les permissions du compte (ADR-014 §4) à chaque contact serveur
  /// qui en porte — login online et refresh. Le dernier mot du serveur fait
  /// foi, y compris l'ensemble vide : un compte dépouillé de ses droits doit
  /// les perdre aussi hors ligne.
  ///
  /// Ne rien faire sur `null` : la réponse ne portait pas le champ, elle ne dit
  /// donc rien de ce compte. Écrire ici effacerait une copie durable valide au
  /// premier contact d'un backend qui ignore encore ADR-014.
  Future<void> updatePermissions(
    String userId,
    List<String>? permissions,
  ) async {
    if (permissions == null) return;
    await _db.update(
      userTable,
      {'permissions': SessionPermissions.encode(permissions)},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Brûle la fenêtre offline du compte (révocation D-09 / refresh rejeté
  /// définitivement) : le prochain login de ce compte devra être online.
  Future<void> clearRefreshExpiresAt(String userId) async {
    await _db.update(
      userTable,
      {'refresh_expires_at': null},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── auth_local_session (singleton id = 1) ────────────────────────────────────

  Future<void> upsertSession(AuthLocalSessionRecord session) async {
    await _db.insert(
      sessionTable,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AuthLocalSessionRecord?> getSession() async {
    final rows = await _db.query(sessionTable, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return AuthLocalSessionRecord.fromMap(rows.first);
  }

  Future<void> updateDegradedMode(SessionMode mode, {required int at}) async {
    await _db.update(sessionTable, {
      'degraded_mode': mode.wire,
      'last_evaluated_at': at,
    }, where: 'id = 1');
  }

  /// Wipe de session (révocation D-09) : supprime la ligne de session et
  /// détache `session_started_at`. **Ne touche ni `auth_local_user` ni
  /// l'outbox** (D-11). L'utilisateur reste « vu sur ce device » → re-login
  /// online puis offline possible.
  Future<void> wipeSession(String userId) async {
    await _db.delete(sessionTable, where: 'id = 1');
    await _db.update(
      userTable,
      {'session_started_at': null},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Ouvre une session locale : pose `session_started_at` sur l'utilisateur.
  Future<void> markSessionStarted(String userId, {required int at}) async {
    await _db.update(
      userTable,
      {'session_started_at': at},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
