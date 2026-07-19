import 'package:school_app_flutter/core/database/table_schema.dart';

/// Tables de la session offline (ADR-010, §5 `auth_local`).
///
/// Ces tables portent l'**état durable de session** — profil vu sur ce device,
/// vérificateur de mot de passe local (Argon2id), état de révocation
/// (`user_version`), ancre temporelle serveur (`last_server_seen_at`), mode de
/// dégradation et garde d'horloge anti-triche. Les **secrets** (access/refresh
/// tokens) restent, eux, dans le secure storage (Keystore) — jamais ici : la
/// base peut être wipée sur révocation, le refresh token doit y survivre.
///
/// Toutes protégées au repos par la DEK SQLCipher du socle (`DatabaseKeyService`).

/// Un enregistrement par utilisateur ayant fait AU MOINS un login online sur ce
/// device (invariant D-01). `user_id` = claim `uid` du JWT (UUID serveur) ; le
/// `sub` du JWT vaut l'email, pas l'UUID (ADR §0.2).
const TableSchema authLocalUserTable = TableSchema(
  name: 'auth_local_user',
  createTableSql: '''
    CREATE TABLE auth_local_user (
      user_id               TEXT PRIMARY KEY,
      -- COLLATE NOCASE : le login offline compare l'email saisi (casse libre,
      -- autofill) à l'email canonique serveur. Le backend online matche en
      -- insensible à la casse ; la base locale doit faire de même, sinon un
      -- compte réellement vu online se verrait refuser le login offline pour
      -- une simple variation de casse (ADR-010 D-01).
      email                 TEXT NOT NULL UNIQUE COLLATE NOCASE,
      first_name            TEXT NOT NULL,
      last_name             TEXT NOT NULL,
      role                  TEXT NOT NULL,
      school_id             TEXT NOT NULL,
      password_verifier     TEXT NOT NULL,
      verifier_salt         TEXT NOT NULL,
      user_version          INTEGER NOT NULL,
      first_online_login_at INTEGER NOT NULL,
      last_server_seen_at   INTEGER NOT NULL,
      session_started_at    INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_auth_local_user_email ON auth_local_user(email)',
  ],
);

/// Session locale active. Singleton (0 ou 1 ligne, `id = 1`). Wipée sur
/// révocation (D-09) — jamais l'outbox, jamais [authLocalUserTable].
const TableSchema authLocalSessionTable = TableSchema(
  name: 'auth_local_session',
  createTableSql: '''
    CREATE TABLE auth_local_session (
      id                 INTEGER PRIMARY KEY CHECK (id = 1),
      user_id            TEXT NOT NULL REFERENCES auth_local_user(user_id),
      degraded_mode      TEXT NOT NULL DEFAULT 'NORMAL'
                           CHECK (degraded_mode IN ('NORMAL','WARNING','READ_ONLY')),
      refresh_expires_at INTEGER NOT NULL,
      last_evaluated_at  INTEGER NOT NULL
    )
  ''',
);

/// Contribution de schéma de la session offline, agrégée par `buildOfflineSchema()`.
///
/// L'anti-triche horloge (D-10) ne nécessite pas de table dédiée : elle repose
/// sur `now(device) < auth_local_user.last_server_seen_at` (saut arrière), qui
/// survit au redémarrage (l'ancre est persistée) — pas d'horloge monotone à
/// stocker.
const List<TableSchema> authOfflineTables = [
  authLocalUserTable,
  authLocalSessionTable,
];
