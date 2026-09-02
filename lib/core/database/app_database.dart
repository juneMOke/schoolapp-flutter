import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/table_schema.dart';

/// Ouvre (et crée/migre au besoin) la base locale chiffrée SQLCipher.
///
/// - [dbKey] : clé de chiffrement (256 bits hex) fournie par [DatabaseKeyService].
/// - [schema] : contributions de tables agrégées (`buildOfflineSchema()`).
///
/// `onCreate` matérialise tout le schéma en un batch (greenfield V1). Les bumps
/// futurs de [AppConstants.offlineDbSchemaVersion] ajoutent des étapes ordonnées
/// dans `onUpgrade`.
Future<Database> openOfflineDatabase({
  required String dbKey,
  required List<TableSchema> schema,
  String dbName = AppConstants.offlineDbName,
  int version = AppConstants.offlineDbSchemaVersion,
}) async {
  final databasesPath = await sqlcipher.getDatabasesPath();
  final path = p.join(databasesPath, dbName);

  return sqlcipher.openDatabase(
    path,
    password: dbKey,
    version: version,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, _) async {
      final batch = db.batch();
      for (final table in schema) {
        batch.execute(table.createTableSql);
        for (final indexSql in table.createIndexSql) {
          batch.execute(indexSql);
        }
      }
      await batch.commit(noResult: true);
    },
    onUpgrade: (db, oldVersion, newVersion) =>
        migrateOfflineDatabase(db, oldVersion, schema, newVersion: newVersion),
  );
}

/// Étapes de migration idempotentes ordonnées, guardées par [oldVersion].
/// Extraite de `onUpgrade` pour être exerçable hors SQLCipher (tests ffi) :
/// le vrai opener est chiffré et non ouvrable en test.
///
/// [newVersion] borne l'escalier par le HAUT. En production il vaut toujours la
/// version courante, et le paramètre ne sert à rien — c'est un outil de test, et
/// il en corrige un défaut réel : un test de palier qui montait jusqu'à la
/// version courante voyait ses attentes satisfaites par une étape ULTÉRIEURE.
/// Le cas concret : le test de la v12 vérifiait que le squelette de notation
/// était vidé ; depuis que la v27 le supprime, l'attente passait même en
/// retirant complètement l'étape v12. Un test vert qui ne teste plus rien est
/// pire que pas de test — il fait croire à une couverture.
///
/// Chaque palier se lit donc `if (_step(...))` et non `if (oldVersion < n)`.
Future<void> migrateOfflineDatabase(
  DatabaseExecutor db,
  int oldVersion,
  List<TableSchema> schema, {
  int newVersion = AppConstants.offlineDbSchemaVersion,
}) async {
  bool upTo(int version) => oldVersion < version && version <= newVersion;

  if (upTo(2)) {
    // v2 — Inscription : ajout des tables de référence (cohorte RE,
    // préinscriptions, socle référentiel). On rejoue tout le schéma en
    // `IF NOT EXISTS` : les tables déjà présentes sont ignorées, seules les
    // nouvelles sont créées (aucune donnée existante n'est touchée).
    for (final table in schema) {
      final existed = await _hasTable(db, table.name);
      await db.execute(_asIfNotExists(table.createTableSql));
      // **Les index d'une table préexistante ne sont PAS rejoués ici.** Cette
      // étape lit le schéma d'AUJOURD'HUI, et une table déjà là porte la forme
      // d'ALORS : un index d'aujourd'hui peut donc citer une colonne qu'elle
      // n'a pas encore. C'est le cas de `ux_emergency_contact_per_student`
      // (v32), qui filtre sur `student_parent.emergency_contact` — colonne
      // ajoutée trente paliers plus loin. Sans cette garde, toute base montant
      // de v1 échouait ici, et avec elle l'escalier entier.
      //
      // Rien n'est perdu : les index d'une table préexistante ont été créés
      // avec elle, et ceux ajoutés depuis le sont par le palier qui les
      // introduit (v17 pour `idx_parents_names`, v32 pour celui-ci). Ce palier
      // ne doit poser que les index des tables qu'il vient, lui, de créer.
      if (existed) continue;
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
  if (upTo(3)) {
    // v3 — Inscription : `source_ref` sur `enrollments` (référence d'origine
    // du dossier, contrat agrégat : matricule RE / id de préinscription PRE).
    // Les bases v1/v2 ont déjà la table → ALTER.
    await db.execute('ALTER TABLE enrollments ADD COLUMN source_ref TEXT');
  }
  if (upTo(4)) {
    // v4 — Présence : passage au modèle SESSION-agrégat (contrat 1.2.0). La
    // racine d'agrégat `attendance_sessions` lève l'ambiguïté des 3 états, et
    // `attendance_records` gagne un lien logique `session_id`.
    await migrateAttendanceToSessionModel(db, schema);
  }
  if (upTo(5)) {
    // v5 — Classe : événement de transfert d'élève offline (régime A). Table
    // neuve, aucun backfill (aucun transfert passé n'était tracé — l'ancien
    // reassign online écrasait le miroir sans historique).
    final transfersTable = schema.firstWhere(
      (t) => t.name == 'classroom_transfers',
    );
    await db.execute(_asIfNotExists(transfersTable.createTableSql));
    for (final indexSql in transfersTable.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (upTo(6)) {
    // v6 — Discipline : agrégat {case, comments[]} (contrat 1.1.0). Table
    // `disciplinary_case_comments` append-only (régime A, uuid honoré) — table
    // neuve, aucun backfill (aucun commentaire passé n'était tracé). Colonne
    // `server_updated_at` sur `disciplinary_cases` : temps de visibilité serveur
    // (base du pull keyset, ADR-008) ; nullable, posée au pull/ACK.
    final commentsTable = schema.firstWhere(
      (t) => t.name == 'disciplinary_case_comments',
    );
    await db.execute(_asIfNotExists(commentsTable.createTableSql));
    for (final indexSql in commentsTable.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
    if (await _hasTable(db, 'disciplinary_cases') &&
        !await _hasColumn(db, 'disciplinary_cases', 'server_updated_at')) {
      await db.execute(
        'ALTER TABLE disciplinary_cases ADD COLUMN server_updated_at INTEGER',
      );
    }
  }
  if (upTo(7)) {
    // v7 — Auth/session offline (ADR-010) : tables `auth_local_user` et
    // `auth_local_session`. Tables neuves, aucun backfill (aucune session
    // offline n'existait avant V1). Rejeu `IF NOT EXISTS` des contributions de
    // `authOfflineTables`.
    for (final name in const ['auth_local_user', 'auth_local_session']) {
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
  if (upTo(8)) {
    // v8 — Notes / Cours (academics + schedule, ADR-006) : tables de référence
    // (`ref_time_slots`, `ref_recurring_sessions`, `ref_cours`) + écriture
    // offline `evaluation` (régime A) et `note_evaluation` (régime C). Tables
    // neuves → aucun backfill. Rejeu `IF NOT EXISTS` des contributions de
    // `academicsOfflineTables`.
    for (final name in const [
      'ref_time_slots',
      'ref_recurring_sessions',
      'ref_cours',
      'evaluation',
      'note_evaluation',
    ]) {
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
  if (upTo(9)) {
    // v9 — Notes / Cours : cache du squelette de notation par cours
    // (`ref_cours_notation`) : arbre période/sous-période + statut d'ouverture +
    // effectif, requis hors ligne au détail cours et à la garde de création.
    // Table neuve → aucun backfill.
    //
    // ⚠️ DDL INLINÉ, et il doit le rester. Cette étape lisait la définition dans
    // le schéma courant (`schema.firstWhere`) — ce qui lève un `StateError` dès
    // que la table en sort, et elle en est sortie en v27 : elle avait cessé
    // d'être alimentée dès la v12. Une base antérieure à la v9 aurait échoué à
    // monter, sur une table que la v27 supprime quelques étapes plus loin.
    //
    // Une étape de migration décrit **le passé**, jamais l'état courant : la
    // recopier depuis le schéma vivant, c'est la faire mentir au premier
    // changement.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ref_cours_notation (
        cours_id TEXT PRIMARY KEY,
        classroom_id TEXT,
        branche_nom TEXT,
        effectif INTEGER NOT NULL DEFAULT 0,
        periodes_json TEXT NOT NULL,
        server_updated_at INTEGER,
        synced_at INTEGER NOT NULL
      )
    ''');
  }
  if (upTo(10)) {
    // v10 — Auth (ADR-010, amendement m4) : borne offline PAR UTILISATEUR
    // `auth_local_user.refresh_expires_at` (nullable). Elle mémorise la borne
    // refresh du dernier contact online de chaque compte, pour autoriser le
    // login offline APRÈS un logout (qui ferme la session sans brûler la
    // fenêtre). Backfill : la borne de la session active (singleton id=1) est
    // recopiée sur son propriétaire ; les autres comptes restent NULL
    // (= reconnexion online exigée, comportement d'avant la migration).
    if (await _hasTable(db, 'auth_local_user') &&
        !await _hasColumn(db, 'auth_local_user', 'refresh_expires_at')) {
      await db.execute(
        'ALTER TABLE auth_local_user ADD COLUMN refresh_expires_at INTEGER',
      );
      await db.execute('''
        UPDATE auth_local_user
        SET refresh_expires_at = (
          SELECT s.refresh_expires_at FROM auth_local_session s
          WHERE s.id = 1 AND s.user_id = auth_local_user.user_id
        )
      ''');
    }
  }
  if (upTo(11)) {
    // v11 — Notes / Cours : purge + rebootstrap forcé après le passage au
    // contrat back scopé ENSEIGNANT (commit `1ec6be3`, DF-K/DF-L). Les pulls
    // antérieurs (cours itéré par classe, séances de l'année entière) n'étaient
    // PAS scopés au prof connecté : la base locale peut porter des cours,
    // évaluations, notes et séances d'AUTRES enseignants.
    //
    // La réconciliation DF-L (éviction des cours absents d'un snapshot) ne se
    // déclenche que sur un cycle **bootstrap** (curseur stocké `null`) — un
    // curseur déjà posé par un pull antérieur empêcherait tout nettoyage
    // automatique. On purge donc ici les données ET les curseurs `sync_meta`
    // des ressources concernées : chaque compte qui migre repart d'un
    // bootstrap propre au prochain pull, déjà scopé enseignant côté serveur.
    // Tables 100% référence (rejouées intégralement par le prochain pull) :
    // purge sans condition, aucune saisie utilisateur n'y vit.
    for (final table in const [
      'ref_cours',
      'ref_cours_notation',
      'ref_recurring_sessions',
    ]) {
      if (await _hasTable(db, table)) {
        await db.delete(table);
      }
    }
    // `evaluation` / `note_evaluation` portent, elles, de la SAISIE. La version
    // initiale de cette étape les purgeait entièrement et supprimait au passage
    // leurs entrées d'outbox, au motif qu'un travail sur un cours mal scopé
    // « n'aurait de toute façon jamais pu être poussé » (DF-L §5.2). Ce motif ne
    // couvre que les cours d'AUTRES enseignants : pour les cours légitimes du
    // prof connecté, une évaluation ou un lot de notes saisis hors ligne et non
    // encore acquittés étaient détruits — en local ET en file — par une simple
    // mise à jour de l'app. Perte silencieuse, sans aucun signal.
    //
    // On ne purge donc que les lignes SYNCED (miroir serveur, recomposé par le
    // pull métier) et on laisse intact tout ce qui n'est pas acquitté
    // (`PENDING_SYNC`, `SYNC_ERROR`), avec ses entrées d'outbox. Coût du choix
    // inverse : au pire, une entrée portant un cours qui n'est pas celui du prof
    // part et se fait rejeter — un échec VISIBLE, préférable à une destruction
    // muette. L'invariant « le wipe ne touche jamais l'outbox » vaut désormais
    // aussi pour les migrations.
    for (final table in const ['evaluation', 'note_evaluation']) {
      if (await _hasTable(db, table) &&
          await _hasColumn(db, table, 'sync_status')) {
        await db.delete(table, where: "sync_status = 'SYNCED'");
      }
    }
    if (await _hasTable(db, 'sync_meta')) {
      await db.delete(
        'sync_meta',
        where:
            "resource LIKE 'academics_cours%' "
            "OR resource LIKE 'academics_evaluations%' "
            "OR resource LIKE 'academics_notes%' "
            "OR resource LIKE 'schedule_sessions%'",
      );
    }
  }
  if (upTo(12)) {
    // v12 — Notes / Cours : bundle `grades-referential` (ETag, cadré prof) —
    // 5 tables réf neuves (`ref_branche`, `ref_ligne_bareme`, `ref_chapitre`,
    // `ref_periode`, `ref_sous_periode`), remplacement d'ensemble à chaque
    // pull. Devient la SEULE source du statut de clôture ; le squelette
    // `ref_cours_notation` (v9, alimenté par un endpoint ONLINE réutilisé) est
    // retiré — vidé ici, la table elle-même n'étant supprimée qu'au palier v27.
    // `evaluation`
    // gagne `chapitre_ids_json` (couverture intra-agrégat, régime A) et
    // `rejection_code` (backstop 422 terminal, DF-N) ; `note_evaluation` gagne
    // `rejection_reason` (motif REJECTED, surfacé à l'UI). Tables neuves →
    // aucun backfill.
    for (final name in const [
      'ref_branche',
      'ref_ligne_bareme',
      'ref_chapitre',
      'ref_periode',
      'ref_sous_periode',
    ]) {
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
    if (await _hasTable(db, 'evaluation')) {
      if (!await _hasColumn(db, 'evaluation', 'chapitre_ids_json')) {
        await db.execute(
          'ALTER TABLE evaluation ADD COLUMN chapitre_ids_json TEXT '
          "NOT NULL DEFAULT '[]'",
        );
      }
      if (!await _hasColumn(db, 'evaluation', 'rejection_code')) {
        await db.execute(
          'ALTER TABLE evaluation ADD COLUMN rejection_code TEXT',
        );
      }
    }
    if (await _hasTable(db, 'note_evaluation') &&
        !await _hasColumn(db, 'note_evaluation', 'rejection_reason')) {
      await db.execute(
        'ALTER TABLE note_evaluation ADD COLUMN rejection_reason TEXT',
      );
    }
    // Le squelette `ref_cours_notation` (workaround online, v9) est retiré au
    // profit du bundle : purge sa donnée + son curseur `sync_meta` résiduel,
    // pour ne rien laisser d'orphelin. La table survit à ce palier ; c'est la
    // v27 qui la supprimera, quinze paliers plus tard — vider tôt et supprimer
    // tard, c'est ce qui laisse une base d'époque intacte si elle s'arrête ici.
    if (await _hasTable(db, 'ref_cours_notation')) {
      await db.delete('ref_cours_notation');
    }
    if (await _hasTable(db, 'sync_meta')) {
      await db.delete(
        'sync_meta',
        where: "resource LIKE 'academics_cours_notation%'",
      );
    }
  }
  if (upTo(13)) {
    // v13 — Inscription : `ref_academic_years.school_id`, colonne neuve pour
    // scoper par école la résolution année courante/précédente (le module
    // `bootstrap` — cache Hive online-only — est remplacé par le référentiel
    // offline déjà pullé pour Inscription, décision FRONT 2026-07-26). Stampée
    // côté client (jamais attendue du payload serveur). Backfill best-effort
    // depuis l'utilisateur de la session active (device mono-école en
    // pratique) ; à défaut reste vide — sans conséquence, le prochain pull
    // référentiel réécrit la colonne pour chaque ligne (`upsertReferential`).
    if (await _hasTable(db, 'ref_academic_years') &&
        !await _hasColumn(db, 'ref_academic_years', 'school_id')) {
      await db.execute(
        'ALTER TABLE ref_academic_years ADD COLUMN school_id TEXT '
        "NOT NULL DEFAULT ''",
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ref_academic_years_school '
        'ON ref_academic_years(school_id)',
      );
      if (await _hasTable(db, 'auth_local_user') &&
          await _hasTable(db, 'auth_local_session')) {
        await db.execute('''
          UPDATE ref_academic_years
          SET school_id = (
            SELECT u.school_id FROM auth_local_user u
            JOIN auth_local_session s ON s.user_id = u.user_id
            WHERE s.id = 1
          )
          WHERE EXISTS (
            SELECT 1 FROM auth_local_user u
            JOIN auth_local_session s ON s.user_id = u.user_id
            WHERE s.id = 1
          )
        ''');
      }
    }
  }
  if (upTo(14)) {
    // v14 — Inscription : `ref_school` (identité du tenant). Le bundle
    // référentiel renvoie désormais `school` + `current`/`previous` au lieu
    // d'une liste plate d'années — table neuve, aucun backfill (réécrite au
    // prochain pull référentiel).
    final table = schema.firstWhere((t) => t.name == 'ref_school');
    await db.execute(_asIfNotExists(table.createTableSql));
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (upTo(15)) {
    // v15 — Inscription : `enrollments.previous_school_level_id`, id
    // référentiel du niveau N-1 (distinct du texte libre
    // `previous_school_level`), utilisé par le calcul auto de la classe
    // cible en réinscription. Seedé uniquement pour les nouveaux dossiers RE
    // — aucun backfill des dossiers existants.
    if (await _hasTable(db, 'enrollments') &&
        !await _hasColumn(db, 'enrollments', 'previous_school_level_id')) {
      await db.execute(
        'ALTER TABLE enrollments ADD COLUMN previous_school_level_id TEXT',
      );
    }
  }
  if (upTo(16)) {
    // v16 — Classe : re-contrat CB-2 en pull KEYSET (`classrooms` bundlé →
    // deux flux indépendants `classrooms`/`classroom-members`, curseur opaque
    // au lieu de l'ancien `updatedSince` ISO). La clé `sync_meta.classrooms`
    // est RÉUTILISÉE mais son format de curseur change de nature : un curseur
    // ISO hérité d'avant ce contrat serait renvoyé tel quel au nouvel endpoint
    // keyset, et son rejet dépendrait d'un 400 strict côté serveur pour
    // s'auto-guérir (cf. `ClassroomPullRepositoryImpl._attemptCycle`). On
    // purge donc ce curseur ici (comme v11 pour `academics_cours%`) : chaque
    // compte qui migre repart d'un bootstrap keyset propre au prochain pull.
    // Aucune perte de donnée (table 100% dérivée de la synchro, réécrite au
    // prochain pull) ; `classroom_members` est une clé neuve, rien à purger.
    if (await _hasTable(db, 'sync_meta')) {
      await db.delete('sync_meta', where: "resource = 'classrooms'");
    }
  }
  if (upTo(17)) {
    // v17 — Inscription : recherche de tuteur existant (étape Tuteurs, popin
    // "Rechercher un parent"). Index composé (nom, prénom) pour accélérer le
    // LIKE de recherche. L'unicité du téléphone reste APPLICATIVE (DAO, cf.
    // upsertDraftGuardianParent) — PAS de UNIQUE INDEX SQL, qui échouerait à
    // la migration si des doublons hérités existent déjà (fratrie/pull
    // serveur non garanti unique).
    if (await _hasTable(db, 'parents')) {
      await db.execute(
        _indexAsIfNotExists(
          'CREATE INDEX idx_parents_names ON parents(last_name, first_name)',
        ),
      );
    }
  }
  if (upTo(18)) {
    // v18 — Notes / Cours : partition par COMPTE des caches de référence cadrés
    // enseignant (`owner_uid`, cf. `core/offline/owner_scope.dart`). Sur une
    // tablette partagée, ces tables et leurs curseurs `sync_meta` étaient
    // uniques alors que chaque prof reçoit un univers différent : le second
    // compte reprenait le curseur du premier, recevait un `304` et ne voyait
    // jamais ses propres séances/cours — tout en lisant ceux de l'autre.
    await _addOwnerScopeToAcademicsRefTables(db, schema);
  }
  if (upTo(19)) {
    // v19 — Éditique offline (ADR-012 D-3) : le reçu provisoire est une
    // PROJECTION de lignes locales. Ces lignes doivent donc porter tout ce que
    // le ticket imprime, sans quoi une réimpression ne peut pas être identique
    // au premier tirage.
    //
    // `payments` : caissier (uid + nom **dénormalisé**) et appareil. La
    // dénormalisation n'est pas de la redondance — `identityOf` peut rendre
    // `null`, et l'entrée d'outbox qui portait l'auteur est supprimée dès
    // l'ACK ; l'uid seul laisserait un ticket anonyme quelques heures après
    // l'encaissement. `receipt_id` capte l'UUID que le serveur envoie déjà.
    //
    // `generated_documents.provisional_number` : conservé APRÈS scellement. Le
    // scellement écrase `number` (`PROV-…` → `ETL-…`) ; sans cette colonne, le
    // ticket papier détenu par un parent n'a plus aucun lien avec le reçu
    // définitif — ce que RG-012-12 suppose pourtant possible.
    //
    // Aucun backfill : les paiements déjà encaissés n'ont jamais connu leur
    // caissier, et les inventer serait pire que de les laisser vides. Les
    // colonnes sont donc toutes NULLABLE, et le ticket sait déjà taire ce
    // qu'il ne connaît pas.
    for (final column in const [
      'cashier_uid',
      'cashier_first_name',
      'cashier_last_name',
      'device_id',
      'receipt_id',
    ]) {
      if (await _hasTable(db, 'payments') &&
          !await _hasColumn(db, 'payments', column)) {
        await db.execute('ALTER TABLE payments ADD COLUMN $column TEXT');
      }
    }
    if (await _hasTable(db, 'generated_documents') &&
        !await _hasColumn(db, 'generated_documents', 'provisional_number')) {
      await db.execute(
        'ALTER TABLE generated_documents ADD COLUMN provisional_number TEXT',
      );
      // Les lignes encore PROVISOIRES portent leur numéro provisoire dans
      // `number` : on le recopie, ce qui le préservera de l'écrasement au
      // prochain scellement. Les lignes déjà DÉFINITIVES ont perdu le leur —
      // rien à récupérer, la colonne reste NULL.
      await db.execute('''
        UPDATE generated_documents
        SET provisional_number = number
        WHERE status = 'PROVISIONAL'
      ''');
    }
  }
  if (upTo(20)) {
    // v20 — Éditique offline (ADR-012 D-5, amendé) : table `payment_anomalies`.
    // Table neuve, aucun backfill — les trop-perçus déjà survenus n'ont laissé
    // aucune trace exploitable (`OverpaymentSignal` était désérialisé puis
    // jeté), et en inventer serait pire que de repartir d'une ardoise propre.
    final table = schema.firstWhere((t) => t.name == 'payment_anomalies');
    await db.execute(_asIfNotExists(table.createTableSql));
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (upTo(21)) {
    // v21 — Éditique offline (ADR-012 D-2/D-7, AM-10) : `editique_cache_entries`,
    // l'INDEX du cache de restitution. Table neuve, aucun backfill — et surtout
    // aucune reprise depuis `generated_documents.pdf_blob` : cette colonne est
    // vide par construction (son `toMap()` ne l'émet pas, et ses deux écritures
    // sont en `ConflictAlgorithm.replace`, qui aurait de toute façon remis à
    // NULL tout octet stocké).
    //
    // Les octets ne rejoignent PAS la base : ils vivront dans des fichiers
    // chiffrés hors base (lot L3.3). Cette étape ne crée donc qu'un index —
    // ce qui permet d'éprouver éviction, mesure et purge avant d'introduire le
    // moindre risque de volumétrie.
    final table = schema.firstWhere((t) => t.name == 'editique_cache_entries');
    await db.execute(_asIfNotExists(table.createTableSql));
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (upTo(22)) {
    // v22 — Éditique offline (ADR-012 RG-012-6/18, lot L3.4) : l'index du cache
    // doit pouvoir décrire une pièce dont la tablette n'a PAS les octets.
    //
    // Le delta de synchronisation apprend à la tablette ce qui existe ailleurs ;
    // les octets, eux, restent tirés un par un, à la demande. Une ligne peut
    // donc n'être qu'une connaissance. `content_sha256` devient nullable pour
    // porter cette différence — c'est elle qui empêche le budget de compter des
    // octets absents et l'éviction d'évincer du vide.
    await _relaxEditiqueCacheContentHash(db, schema);
  }
  if (upTo(23)) {
    // v23 — Éditique offline (ADR-012, lot back B5) : l'index du cache doit
    // pouvoir dire qu'une pièce a été RETIRÉE par le serveur.
    //
    // Le delta descend `cancelledAt` et son motif depuis B5 ; sans ces colonnes
    // le front les jetait, et une pièce annulée continuait d'être proposée hors
    // ligne avec un bouton qui ressort un document sans valeur.
    //
    // Deux colonnes nullables, ajoutées par `ALTER` — aucun backfill possible :
    // les pièces déjà en cache n'ont jamais connu leur annulation, et le
    // prochain cycle de delta la leur apprendra si elle existe.
    //
    // Aucun index neuf, et c'est voulu : `ALTER` ne rejoue pas `createIndexSql`,
    // donc un index posé ici n'existerait que sur les installations neuves. Les
    // deux lectures concernées sont déjà servies — l'index d'éviction reste
    // partiel sur `content_sha256` (une pièce annulée garde ses octets et reste
    // évinçable), et le catalogue passe par `idx_editique_cache_subject`.
    for (final column in const ['cancelled_at', 'cancellation_reason']) {
      // La garde n'est pas cosmétique : une base v≤20 traverse d'abord le
      // palier v21, qui crée la table depuis le DDL **canonique** — donc avec
      // ces deux colonnes. Sans elle, `duplicate column name` ferait échouer
      // toute migration venue d'avant la v21.
      if (await _hasTable(db, 'editique_cache_entries') &&
          !await _hasColumn(db, 'editique_cache_entries', column)) {
        await db.execute(
          'ALTER TABLE editique_cache_entries ADD COLUMN $column '
          '${column == 'cancelled_at' ? 'INTEGER' : 'TEXT'}',
        );
      }
    }
  }
  // ⚠️ v24 est un TROU PERMANENT — aucune migration ne porte ce numéro, et
  // aucune ne doit le reprendre. `feature/manage_app_printing` l'avait sautée
  // en réservant la v24 aux permissions ; c'est elle qui a fusionné en
  // premier, donc les permissions ont renuméroté en v26 (ci-dessous) selon sa
  // propre consigne. Le numéro 24 reste néanmoins BRÛLÉ : des tablettes de
  // développement ont tourné sur l'ancienne v24 « permissions » et portent une
  // base estampillée 24. Y recoller une autre migration la rendrait invisible
  // sur ces postes — base marquée à jour, colonne absente, panne au premier
  // SQL qui la lit. Un trou de numéro ne coûte rien ; un doublon coûte une base.
  if (upTo(25)) {
    // v25 — Rattrapage d'impression du ticket de perception : retenir qu'un
    // papier est SORTI pour ce versement.
    //
    // Rien ne le savait jusqu'ici. La ligne de `generated_documents` d'un
    // paiement n'est créée qu'au scellement serveur, donc un encaissement
    // fraîchement écrit n'a aucune trace d'impression — et sans trace, offrir
    // « imprimer » sur un paiement déjà servi reviendrait à ouvrir la
    // réimpression, que l'ADR-013 interdit.
    //
    // Colonne **strictement locale**, jamais poussée ni descendue : « ce poste
    // a sorti le papier » est un fait d'appareil, pas une donnée métier. Aucun
    // backfill possible ni souhaitable — les versements antérieurs ont été
    // servis ou non, et personne ne peut plus le dire ; ils restent donc
    // éligibles au rattrapage, ce qui est le pire cas acceptable.
    // ⚠️ `_hasTable` AVANT `_hasColumn`, comme la v23 : ce migrateur s'exerce
    // aussi sur des bases partielles — chaque test de palier ne crée que les
    // tables qui le concernent. Sans cette garde, un `ALTER` sur une table
    // absente fait échouer l'escalier entier, et donc tous les autres paliers.
    if (await _hasTable(db, 'payments') &&
        !await _hasColumn(db, 'payments', 'ticket_printed_at')) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN ticket_printed_at INTEGER',
      );
    }
  }
  if (upTo(26)) {
    // v26 — Auth (ADR-014 §4) : `auth_local_user.permissions`.
    //
    // ⚠️ Renumérotée depuis la v24 au rebase sur `main` : l'impression (v25) a
    // fusionné en premier, et un palier posé SOUS la version courante ne serait
    // jamais rejoué sur une base déjà estampillée 25 — colonne absente, panne
    // au premier SQL qui la lit.
    //
    // L'ensemble des permissions ne descend qu'au login et au refresh — jamais
    // sur les pages de sync. La copie de session (secure storage) est effacée
    // au logout ; sans copie DURABLE par compte, le login offline suivant
    // reconstruirait une session à zéro droit et l'agent, hors ligne, ne
    // verrait plus un seul module.
    //
    // Une colonne nullable, sans backfill : les comptes déjà connus n'ont
    // jamais reçu d'ensemble et NULL dit exactement « aucune permission
    // connue » — le prochain contact serveur la renseignera.
    //
    // La garde `_hasColumn` n'est pas cosmétique ici : les tablettes de dev
    // passées par l'ancienne v24 portent DÉJÀ la colonne, et sans elle leur
    // montée 24→26 échouerait sur `duplicate column name`.
    if (await _hasTable(db, 'auth_local_user') &&
        !await _hasColumn(db, 'auth_local_user', 'permissions')) {
      await db.execute(
        'ALTER TABLE auth_local_user ADD COLUMN permissions TEXT',
      );
    }
  }

  if (upTo(27)) {
    // v27 — hygiène (ADR-015 F8). Deux gestes sans rapport, un seul palier :
    // aucun des deux ne justifie à lui seul de faire monter tout le parc.

    // ── 1. PII élève sans destination ──────────────────────────────────────
    //
    // `students.phone_number` et `students.email` descendaient par le pull
    // hydratant d'Inscription et ne remontaient jamais. Personne ne les lisait :
    // aucune requête ne les nomme, et le seul chemin vers l'écran
    // (`LocalEnrollmentDetailMapper`) les laissait tomber — `StudentDetail` ne
    // les déclare pas. Ils traversaient trois couches pour être abandonnés à la
    // dernière, en laissant de la donnée personnelle au repos sur chaque
    // tablette du parc.
    //
    // On cesse de les écrire (côté DAO) ET on efface ce qui est déjà descendu :
    // sans ce second geste, le lot n'aurait réduit que le flux futur, et chaque
    // tablette déjà en service aurait gardé ses numéros indéfiniment.
    //
    // ⚠️ Un `UPDATE`, jamais un `DROP COLUMN`. SQLite ne sait pas supprimer une
    // colonne sans reconstruire la table — et `students` est la source de
    // Facturation, du Contrôle des frais, de Documents et du ticket imprimé
    // (tout y arrive par `JOIN students`). Le gain d'une reconstruction serait
    // la définition de deux colonnes vides ; le risque, une table centrale.
    // Elles restent donc déclarées, inertes.
    if (await _hasTable(db, 'students')) {
      if (await _hasColumn(db, 'students', 'phone_number')) {
        await db.execute('UPDATE students SET phone_number = NULL');
      }
      if (await _hasColumn(db, 'students', 'email')) {
        await db.execute('UPDATE students SET email = NULL');
      }
      // Hors du garde de colonne : un index est un objet indépendant de la
      // colonne qu'il porte, et le confondre avec elle ferait survivre l'index
      // à une base où la colonne aurait disparu. `IF EXISTS` fait le reste.
      //
      // Il indexait une colonne qu'aucune requête n'interrogeait : du coût
      // d'écriture pur à chaque INSERT d'élève. Le retirer est immédiat,
      // contrairement à un `DROP COLUMN`.
      await db.execute('DROP INDEX IF EXISTS idx_students_phone');
    }

    // ── 2. `ref_cours_notation`, squelette remplacé en v12 ─────────────────
    //
    // La table a cessé d'être alimentée quand le détail de notation a pris sa
    // source réelle, mais elle continuait d'être CRÉÉE sur toute base neuve —
    // et dans chaque base de test. On la retire du schéma et on la supprime ici.
    //
    // ⚠️ Son DDL est désormais inliné dans l'étape v9 : celle-ci le lisait par
    // `schema.firstWhere`, qui lève un `StateError` dès que la table quitte le
    // schéma. Toute base antérieure à la v9 aurait échoué à monter.
    await db.execute('DROP TABLE IF EXISTS ref_cours_notation');
  }
  if (upTo(28)) {
    // v28 — Facturation : `payments.payer_phone_number`, le numéro du payeur
    // saisi au guichet.
    //
    // Nullable, et il doit le rester : le palier ne fait pas remonter le passé.
    // Aucun versement déjà en base n'a de numéro à recevoir, aucun backfill
    // n'est possible (le tuteur de l'élève N'EST PAS le payeur — c'est
    // précisément ce que la saisie établit), et le contrat de pull ne portera
    // rien pour les versements scellés avant l'évolution. Ces lignes gardent
    // donc `NULL`, qui se lit « on ne sait pas », pas « pas de numéro ».
    //
    // C'est ce que l'annuaire de payeurs exploite : une ligne sans numéro est
    // proposable par son identité, jamais rapprochée par son numéro.
    //
    // Pas d'index. La recherche par numéro compare des CHIFFRES normalisés
    // (`PhoneNumberSql.matchKey`, `LIKE '%…%'`), qu'aucun index sur la valeur
    // brute ne sert — il ne coûterait que des écritures à chaque encaissement.
    if (await _hasTable(db, 'payments') &&
        !await _hasColumn(db, 'payments', 'payer_phone_number')) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN payer_phone_number TEXT',
      );
    }
  }
  if (upTo(29)) {
    // v29 — Facturation : `payments.collected_by_id` / `collected_by_name`,
    // l'encaisseur tel que le SERVEUR l'attribue.
    //
    // Le contrat de synchro le transporte depuis l'évolution du back
    // (`GET /sync/payments` : `collectedById`, `collectedByName`). Jusqu'ici
    // l'écran de détail affichait un « Encaissé par » vide pour tout versement
    // venu d'un autre guichet — non par oubli, mais parce qu'aucune donnée ne
    // franchissait la synchro. Ces deux colonnes sont ce chemin.
    //
    // Nullables, et pour deux raisons distinctes qu'il ne faut pas confondre :
    // les versements scellés avant l'évolution du contrat n'en portent aucun
    // (le passé ne remonte pas), et un versement saisi ICI n'en a pas encore
    // tant que le serveur ne l'a pas accusé — il porte alors ses `cashier_*`,
    // qui suffisent.
    //
    // Aucun backfill possible, et surtout aucun souhaitable : recopier les
    // `cashier_*` locaux ici inventerait une attribution SERVEUR qui n'a
    // jamais été prononcée.
    //
    // DDL INLINE, jamais lu du schéma vivant : une étape qui interroge
    // `schema.firstWhere` cesse de monter au premier retrait de table.
    if (await _hasTable(db, 'payments')) {
      if (!await _hasColumn(db, 'payments', 'collected_by_id')) {
        await db.execute(
          'ALTER TABLE payments ADD COLUMN collected_by_id TEXT',
        );
      }
      if (!await _hasColumn(db, 'payments', 'collected_by_name')) {
        await db.execute(
          'ALTER TABLE payments ADD COLUMN collected_by_name TEXT',
        );
      }
    }
  }

  if (upTo(30)) {
    // v30 — Configuration : `provisioning_drafts`, le brouillon de mise en
    // service de l'école.
    //
    // Création pure, aucune donnée touchée : le module n'existait pas avant, et
    // rien dans la base ne s'y rattache. Un appareil qui monte de v29 n'a
    // simplement pas de brouillon, ce qui est l'état nominal d'une école déjà
    // paramétrée.
    //
    // DDL INLINE, jamais lu du schéma vivant : une étape qui interroge
    // `schema.firstWhere` cesse de monter au premier retrait de table.
    if (!await _hasTable(db, 'provisioning_drafts')) {
      await db.execute('''
        CREATE TABLE provisioning_drafts (
          school_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          payload TEXT NOT NULL,
          step INTEGER NOT NULL DEFAULT 0,
          max_step INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (school_id, user_id)
        )
      ''');
    }
  }
  if (upTo(31)) {
    // v31 — Boutique (ADR-020) : le catalogue et les ventes de la caisse
    // point-de-vente.
    //
    // Création pure, aucune donnée touchée : le module n'existait pas. Un
    // appareil qui monte de v30 reçoit quatre tables vides, et le premier
    // bundle référentiel remplit le catalogue.
    //
    // DDL INLINE, jamais lu du schéma vivant : une étape qui interroge
    // `schema.firstWhere` cesse de monter au premier retrait de table.
    if (!await _hasTable(db, 'ref_boutique_articles')) {
      await db.execute('''
        CREATE TABLE ref_boutique_articles (
          id TEXT PRIMARY KEY,
          school_id TEXT NOT NULL,
          academic_year_id TEXT NOT NULL,
          code TEXT NOT NULL,
          label TEXT NOT NULL,
          family TEXT NOT NULL,
          pricing_mode TEXT NOT NULL,
          unit_price_in_cents INTEGER,
          currency TEXT NOT NULL,
          updated_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_ref_boutique_articles_scope '
        'ON ref_boutique_articles(school_id, academic_year_id)',
      );
    }
    if (!await _hasTable(db, 'ref_boutique_article_level_prices')) {
      await db.execute('''
        CREATE TABLE ref_boutique_article_level_prices (
          article_id TEXT NOT NULL,
          school_level_id TEXT NOT NULL,
          price_in_cents INTEGER NOT NULL,
          PRIMARY KEY (article_id, school_level_id)
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_ref_boutique_level_prices_article '
        'ON ref_boutique_article_level_prices(article_id)',
      );
    }
    if (!await _hasTable(db, 'boutique_sales')) {
      await db.execute('''
        CREATE TABLE boutique_sales (
          id TEXT PRIMARY KEY,
          school_id TEXT NOT NULL,
          academic_year_id TEXT NOT NULL,
          payer_first_name TEXT,
          payer_last_name TEXT NOT NULL,
          payer_middle_name TEXT,
          payer_phone_number TEXT,
          payer_name TEXT,
          collected_by_id TEXT,
          collected_by_name TEXT,
          total_in_cents INTEGER NOT NULL,
          currency TEXT NOT NULL,
          sold_at TEXT NOT NULL,
          receipt_document_id TEXT,
          receipt_number TEXT,
          device_id TEXT,
          sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
          sync_error TEXT,
          synced_at INTEGER,
          server_updated_at TEXT,
          updated_at INTEGER NOT NULL DEFAULT 0,
          ticket_printed_at INTEGER
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_boutique_sales_scope '
        'ON boutique_sales(school_id, academic_year_id)',
      );
      await db.execute(
        'CREATE INDEX idx_boutique_sales_sold_at ON boutique_sales(sold_at)',
      );
      await db.execute(
        'CREATE INDEX idx_boutique_sales_sync ON boutique_sales(sync_status)',
      );
    }
    if (!await _hasTable(db, 'boutique_sale_lines')) {
      await db.execute('''
        CREATE TABLE boutique_sale_lines (
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          article_id TEXT NOT NULL,
          article_label TEXT NOT NULL,
          article_code TEXT,
          beneficiary_student_id TEXT,
          beneficiary_name TEXT,
          school_level_id TEXT,
          size TEXT,
          quantity INTEGER NOT NULL,
          unit_price_in_cents INTEGER NOT NULL,
          line_total_in_cents INTEGER NOT NULL,
          catalog_price_in_cents INTEGER,
          position INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_boutique_sale_lines_sale '
        'ON boutique_sale_lines(sale_id)',
      );
    }
  }

  if (upTo(32)) {
    // v32 — Inscription : les quatre champs que le guichet saisit et que le
    // dossier ne savait pas porter.
    //
    // DDL INLINE, jamais lu du schéma vivant : une étape qui interroge
    // `schema.firstWhere` cesse de monter au premier retrait de table.
    if (await _hasTable(db, 'enrollments')) {
      if (!await _hasColumn(db, 'enrollments', 'former_student')) {
        // NOT NULL avec défaut : la colonne existe côté serveur sous la même
        // contrainte, et un dossier sans déclaration n'est pas « inconnu » mais
        // « pas ancien ».
        await db.execute(
          'ALTER TABLE enrollments '
          'ADD COLUMN former_student INTEGER NOT NULL DEFAULT 0',
        );
        // Backfill best-effort, et strictement le même compromis que V100 côté
        // serveur : le type d'inscription est la SEULE information que
        // l'existant porte pour distinguer un ancien élève. Ce n'est pas que
        // les deux notions soient synonymes — elles divergent dès qu'une école
        // démarre sur l'application — c'est qu'aucune déclaration de guichet
        // n'a jamais été possible sur ces lignes.
        await db.execute(
          'UPDATE enrollments SET former_student = 1 '
          "WHERE enrollment_type = 'RE_ENROLLMENT'",
        );
      }
      if (!await _hasColumn(db, 'enrollments', 'medical_notes')) {
        await db.execute(
          'ALTER TABLE enrollments ADD COLUMN medical_notes TEXT',
        );
      }
    }

    if (await _hasTable(db, 'student_parent')) {
      if (!await _hasColumn(db, 'student_parent', 'emergency_contact')) {
        await db.execute(
          'ALTER TABLE student_parent '
          'ADD COLUMN emergency_contact INTEGER NOT NULL DEFAULT 0',
        );
      }
      // Index unique PARTIEL — il ne contraint que les lignes à 1. Créé APRÈS
      // la colonne et jamais avant : sur une base existante, toutes les lignes
      // valent 0, donc aucune ne le viole à la création.
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_emergency_contact_per_student '
        'ON student_parent(student_id) WHERE emergency_contact = 1',
      );
    }

    if (await _hasTable(db, 'ref_previous_year_students') &&
        !await _hasColumn(db, 'ref_previous_year_students', 'medical_notes')) {
      // Reste NULL jusqu'au prochain pull de la cohorte : la fiche santé N-1
      // n'est pas reconstituable localement, et une colonne vide se lit
      // correctement « pas encore descendue ».
      await db.execute(
        'ALTER TABLE ref_previous_year_students ADD COLUMN medical_notes TEXT',
      );
    }
  }

  if (upTo(33)) {
    // v33 — Multi-devise : les arriérés N-1 quittent la ligne de l'élève pour
    // une table fille, une entrée PAR DEVISE.
    //
    // La colonne scalaire étiquetait la somme de tous les postes avec la devise
    // du premier : un élève devant 425,00 $ et 90 000 FC se voyait annoncer
    // « 90 425,00 $ ».
    //
    // **Recréée plutôt que reconstruite par copie.** `ref_previous_year_students`
    // est 100 % dérivée de la synchro — le seed la remplace en bloc à chaque
    // pull — donc rien n'est perdu à la vider, à condition de **rembobiner son
    // curseur** : une purge sans rembobinage laisserait la cohorte vide jusqu'au
    // prochain rollover d'année, et le guichet sans vivier de réinscription.
    //
    // Le curseur est scopé par année (`enrollment_reenrollment_cohort:<yearId>`),
    // d'où le `LIKE` : on ne connaît pas ici l'année courante, et en laisser un
    // seul debout suffirait à faire répondre 304 au prochain pull.
    //
    // **Rejouable**, et c'est ce que la garde suivante achète : l'étape se
    // décide sur la FORME RÉELLE de la table — la colonne scalaire est-elle
    // encore là ? — et non sur un drapeau. Un `DROP` inconditionnel
    // redétruirait, à chaque rejeu, une cohorte fraîchement redescendue.
    final hadScalarBalance =
        await _hasTable(db, 'ref_previous_year_students') &&
        await _hasColumn(
          db,
          'ref_previous_year_students',
          'previous_balance_in_cents',
        );

    if (hadScalarBalance) {
      await db.execute('DROP TABLE ref_previous_year_students');
      // `sync_meta` manque sur les bases partielles des tests de palier : une
      // migration qui suppose une table voisine cesse de monter le jour où
      // quelqu'un la retire.
      if (await _hasTable(db, 'sync_meta')) {
        await db.delete(
          'sync_meta',
          where: 'resource = ? OR resource LIKE ?',
          whereArgs: const [
            'enrollment_reenrollment_cohort',
            'enrollment_reenrollment_cohort:%',
          ],
        );
      }
    }

    for (final name in const [
      'ref_previous_year_students',
      'ref_previous_year_student_balances',
    ]) {
      if (await _hasTable(db, name)) continue;
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(table.createTableSql);
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }

  if (upTo(34)) {
    // v34 — Multi-devise : `payments` perd ses montants, qui se dérivent
    // désormais de ses imputations.
    //
    // Ce n'étaient pas des propriétés du versement : un résumé de ses
    // allocations, stockable en scalaire tant qu'il n'y avait qu'une devise. Un
    // passage au guichet qui solde une créance en dollars ET une en francs n'a
    // pas de montant unique.
    //
    // **Reconstruite avec COPIE**, jamais vidée : `payments` porte de l'argent
    // encaissé, dont des lignes qui n'ont pas encore été poussées. En perdre une
    // serait perdre un encaissement que le reçu papier atteste déjà.
    await _dropPaymentScalarAmounts(db, schema);
  }

  if (upTo(35)) {
    // v35 — Multi-devise à la caisse : la DEVISE descend sur la ligne, et la
    // vente perd ses montants.
    //
    // C'est l'article qui est tarifé dans une unité, donc la ligne : un panier
    // peut en mêler deux, et c'est un acte de caisse — une vente, un reçu, pas
    // deux. La devise envoyée est celle **réellement encaissée**, enregistrée
    // telle quelle et jamais déduite du catalogue : la caisse vend hors ligne
    // sur une copie qui peut précéder un changement de devise, et déduire
    // imprimerait des dollars sur un reçu dont le tiroir contient des francs.
    await _moveBoutiqueCurrencyToLines(db, schema);
  }

  if (upTo(36)) {
    // v36 — Réductions par élève (ADR-021 V1) : le catalogue du barème, et la
    // mémoire de qui y a droit.
    //
    // **Trois tables neuves, aucune colonne touchée, aucun backfill.** La V1 ne
    // calcule rien : `student_charges` garde exactement la forme qu'elle a, et
    // les colonnes que le back ajoute de son côté (`gross_amount_in_cents`,
    // `reduction_code`) ne descendent pas ici — rien ne les lirait.
    //
    // Les deux tables de barème n'ont pas d'année mais ont un `school_id` : le
    // barème descend à la RACINE du bundle référentiel. Leur purge au pull sera
    // donc scopée par école, et cette colonne est ce qui le rend possible.
    for (final name in const [
      'ref_reduction_types',
      'ref_reduction_lines',
      'enrollment_reductions',
    ]) {
      if (await _hasTable(db, name)) continue;
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(table.createTableSql);
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }

  if (upTo(37)) {
    // v37 — le barème de réductions sur la forme que le serveur sert vraiment.
    //
    // La v36 a été écrite AVANT que le back ne livre l'ADR-021 : elle attendait
    // deux sections à plat, chacune portant un `id`. Le contrat livré n'en donne
    // aucun — un type est identifié par son code dans son école, une ligne par
    // sa rubrique dans son type — et il nomme le taux `percentage`.
    await _rebuildReductionCatalog(db, schema);
  }

  if (upTo(38)) {
    // v38 — `payment_allocations.fee_tariff_id` : l'imputation dit désormais sur
    // QUELLE LIGNE DE GRILLE l'argent a été reçu, plus seulement de quelle
    // nature était le frais.
    //
    // Le serveur admet plusieurs lignes d'une même nature sur un niveau depuis
    // V94 — un minerval en sept tranches — et refuse alors d'imputer au hasard
    // (422 `AMBIGUOUS_FEE_CODE`). Le tarif est le seul discriminant utilisable
    // des deux côtés : il vient du référentiel servi par le serveur, donc il ne
    // peut jamais être provisoire, là où l'id de créance, lui, peut l'être.
    //
    // **Nullable, et aucun backfill ici.** Une créance *ad hoc* n'a légitimement
    // pas de tarif. Et les imputations déjà en base n'en ont pas non plus : les
    // renseigner suppose de retrouver la créance visée, ce qui n'est pas un
    // geste de schéma — c'est la reprise des versements en attente, qui doit
    // lire un grand-livre déjà juste et se rejouer seule.
    if (await _hasTable(db, 'payment_allocations') &&
        !await _hasColumn(db, 'payment_allocations', 'fee_tariff_id')) {
      await db.execute(
        'ALTER TABLE payment_allocations ADD COLUMN fee_tariff_id TEXT',
      );
    }
  }

  if (upTo(39)) {
    // v39 — `ref_fee_tariffs.code` : ce qui distingue deux lignes de MÊME
    // NATURE sur un niveau (« T1 » et « T2 » d'un minerval étalé).
    //
    // Le serveur le sert déjà dans le bundle référentiel
    // (`FeeTariffSummaryDto.code`) ; le front le jetait. Sans lui, la créance ne
    // peut être nommée que par sa nature, et sept tranches de minerval
    // s'affichent sept fois « Minerval » — au guichet comme sur le reçu.
    //
    // **Aucun backfill, et il n'en faut pas.** Un cache référentiel se jette, il
    // ne se rattrape pas (leçon de v37) : `replaceTariffsForYears` réécrit
    // chaque ligne des années du bundle au pull suivant. Entre ce palier et ce
    // pull, `code` vaut NULL — la désignation retombe alors sur le libellé seul,
    // c'est-à-dire sur le comportement d'aujourd'hui.
    if (await _hasTable(db, 'ref_fee_tariffs') &&
        !await _hasColumn(db, 'ref_fee_tariffs', 'code')) {
      await db.execute('ALTER TABLE ref_fee_tariffs ADD COLUMN code TEXT');
    }
  }
  if (upTo(40)) {
    // v40 — le taux de guichet (perçu ≠ imputé, lot F0). Table de cache
    // référentiel, remplie par le pull : création pure, aucune donnée touchée.
    //
    // Un appareil qui monte de v39 reçoit une table vide, et n'ouvre donc
    // aucune saisie bi-devise tant que le premier bundle n'a rien apporté —
    // c'est le comportement voulu : le guichet PROPOSE un taux, il ne
    // l'invente pas.
    //
    // DDL INLINE, jamais lu du schéma vivant : une étape qui interroge
    // `schema.firstWhere` cesse de monter au premier retrait de table.
    if (!await _hasTable(db, 'ref_exchange_rates')) {
      await db.execute('''
        CREATE TABLE ref_exchange_rates (
          school_id TEXT NOT NULL DEFAULT '',
          base TEXT NOT NULL,
          quote TEXT NOT NULL,
          effective_from TEXT NOT NULL,
          rate_micros INTEGER NOT NULL,
          divergence_band_bp INTEGER,
          set_by TEXT,
          synced_at INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (school_id, base, quote, effective_from)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ref_exchange_rates_pair '
        'ON ref_exchange_rates(school_id, base, quote, effective_from)',
      );
    }
  }
  if (upTo(41)) {
    // v41 — `payment_tenders` : ce qui est ENTRÉ DANS LE TIROIR, à côté de ce
    // qui a été imputé (lot F2).
    //
    // ## Le backfill n'est pas une commodité, c'est ce qui évite deux voies de
    // lecture
    //
    // Le serveur écrit une ligne d'identité pour chaque paiement déjà en base
    // (lot E1) — mais le pull des paiements est un DELTA par curseur : il ne
    // redescend que ce qui bouge. Les versements déjà en base LOCALE ne seront
    // donc jamais retouchés, et resteraient sans tender pour toujours.
    //
    // L'alternative serait un `if tenders is empty then payment_allocations` à
    // la lecture. C'est exactement ce que le serveur s'interdit, et pour la même
    // raison : deux voies de lecture divergent toujours une fois. Une
    // réimpression de ticket, six mois plus tard, est le moment où ça se
    // verrait.
    //
    // ## Identité : perçu = imputé, taux 1
    //
    // Une ligne par `(payment_id, currency)`, agrégée depuis les imputations.
    // C'est vrai de tout l'historique : avant la V2, il n'existait aucun moyen
    // d'encaisser dans une autre devise que celle de la créance.
    //
    // Rejouable : le `WHERE NOT EXISTS` garde le palier idempotent. Surtout pas
    // d'`INSERT OR REPLACE` — la paire avec une clé d'unicité est une
    // destruction silencieuse, déjà payée une fois sur les créances.
    //
    // DDL INLINE, jamais lu du schéma vivant.
    if (!await _hasTable(db, 'payment_tenders')) {
      await db.execute('''
        CREATE TABLE payment_tenders (
          id TEXT PRIMARY KEY,
          client_uuid TEXT NOT NULL,
          payment_id TEXT NOT NULL,
          amount_in_cents INTEGER NOT NULL,
          currency TEXT NOT NULL,
          rate_micros INTEGER NOT NULL DEFAULT 1000000,
          pivot_currency TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_tenders_payment '
        'ON payment_tenders(payment_id)',
      );
    }
    if (await _hasTable(db, 'payment_allocations')) {
      // uuid v4 forgé en SQL pur (RFC 4122), comme le backfill des sessions de
      // présence : aucune dépendance Dart, donc migration exerçable en ffi.
      await db.execute('''
        INSERT INTO payment_tenders
          (id, client_uuid, payment_id, amount_in_cents, currency,
           rate_micros, pivot_currency)
        SELECT
          lower(
            hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
            substr(hex(randomblob(2)), 2) || '-' ||
            substr('89ab', abs(random()) % 4 + 1, 1) ||
            substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
          ),
          lower(
            hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
            substr(hex(randomblob(2)), 2) || '-' ||
            substr('89ab', abs(random()) % 4 + 1, 1) ||
            substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
          ),
          a.payment_id,
          SUM(a.amount_in_cents),
          a.currency,
          1000000,
          a.currency
        FROM payment_allocations a
        WHERE NOT EXISTS (
          SELECT 1 FROM payment_tenders t
          WHERE t.payment_id = a.payment_id AND t.currency = a.currency
        )
        GROUP BY a.payment_id, a.currency
      ''');
    }
  }
  if (upTo(42)) {
    // v42 — `boutique_sale_tenders` : ce qui est ENTRÉ DANS LE TIROIR pour une
    // vente, à côté de ce qui a été vendu. Symétrique exact de la v41.
    //
    // **Le backfill obéit à la même logique**, et pour la même raison : le pull
    // des ventes est un delta par curseur, il ne redescendra jamais celles qui
    // sont déjà en base locale. Sans identité posée ici, elles resteraient sans
    // tender pour toujours — et la seule issue serait un « pas de tender ⇒ lire
    // les lignes » à la lecture, c'est-à-dire deux voies qui divergeront.
    //
    // Identité : perçu = vendu, taux 1. C'est vrai de tout l'historique — avant
    // ce lot, la caisse boutique n'avait aucun moyen d'encaisser dans une autre
    // devise que celle du catalogue.
    //
    // Rejouable : `WHERE NOT EXISTS` garde le palier idempotent. Jamais
    // d'`INSERT OR REPLACE` — la paire avec une clé d'unicité est une
    // destruction silencieuse.
    //
    // DDL INLINE, jamais lue du schéma vivant.
    if (!await _hasTable(db, 'boutique_sale_tenders')) {
      await db.execute('''
        CREATE TABLE boutique_sale_tenders (
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          amount_in_cents INTEGER NOT NULL,
          currency TEXT NOT NULL,
          rate_micros INTEGER NOT NULL DEFAULT 1000000,
          pivot_currency TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_boutique_sale_tenders_sale '
        'ON boutique_sale_tenders(sale_id)',
      );
    }
    if (await _hasTable(db, 'boutique_sale_lines')) {
      // uuid v4 forgé en SQL pur (RFC 4122) : aucune dépendance Dart, donc
      // migration exerçable en ffi.
      await db.execute('''
        INSERT INTO boutique_sale_tenders
          (id, sale_id, amount_in_cents, currency, rate_micros, pivot_currency)
        SELECT
          lower(
            hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
            substr(hex(randomblob(2)), 2) || '-' ||
            substr('89ab', abs(random()) % 4 + 1, 1) ||
            substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
          ),
          l.sale_id,
          SUM(l.line_total_in_cents),
          l.currency,
          1000000,
          l.currency
        FROM boutique_sale_lines l
        WHERE NOT EXISTS (
          SELECT 1 FROM boutique_sale_tenders t
          WHERE t.sale_id = l.sale_id AND t.currency = l.currency
        )
        GROUP BY l.sale_id, l.currency
      ''');
    }
  }
  if (upTo(43)) {
    // v43 — le payeur devient FACULTATIF, des deux côtés du guichet.
    //
    // Contrepartie de la V114 serveur : `payments.payer_first_name` /
    // `payer_last_name` et `boutique_sales.payer_last_name` perdent leur
    // `NOT NULL`. Côté serveur ces colonnes étaient nullables depuis sa V10 —
    // c'était l'arête HTTP, et elle seule, qui exigeait un nom. Ici c'était le
    // schéma lui-même.
    //
    // Ce que l'exigence coûtait : la file attend pendant qu'on demande son état
    // civil à quelqu'un qui achète un cahier, et le guichetier tape « X » pour
    // avancer. Le champ a alors l'air renseigné et ne désigne personne — pire
    // qu'un champ vide, parce qu'on ne peut plus distinguer les deux.
    //
    // **Aucune donnée n'est perdue** : la reconstruction recopie colonne pour
    // colonne, et ce palier n'ouvre une porte que pour les écritures suivantes.
    await _relaxPayerIdentity(db, schema);
  }
}

/// Étape v43 : les colonnes d'identité du payeur perdent leur `NOT NULL`.
///
/// SQLite ne sait pas relâcher une contrainte de colonne : on reconstruit les
/// deux tables sur leur forme d'aujourd'hui et on recopie. Même patron qu'aux
/// paliers v33/v34, et pour la même raison.
///
/// ## Les `''` hérités deviennent `NULL`
///
/// C'est la moitié utile du palier. `boutique_sale_pull_dao` repliait sur `''`
/// pour satisfaire le `NOT NULL` quand le delta descendait une vente sans nom :
/// une vente anonyme se relisait donc comme une vente au nom VIDE. Assez pour
/// qu'un ticket imprime un cadre « Payeur » creux — sur une pièce, un cadre vide
/// se lit comme une mention effacée, pas comme une absence.
///
/// `NULL` et `''` ne disent pas la même chose et ne doivent pas cohabiter :
/// « pas de payeur » est un fait, pas un nom de longueur zéro. C'est la règle
/// que le serveur s'est donnée en V114, et deux écritures pour un même fait
/// divergent toujours une fois.
///
/// Le téléphone n'est pas normalisé : il est nullable depuis la v28 et n'a
/// jamais eu de repli sur `''`.
///
/// Rejouable : se garde sur la forme réelle des tables. Sur une base déjà en
/// v43, `_isColumnNotNull` rend faux et il n'y a rien à faire — mais la
/// normalisation, elle, est idempotente et se rejoue sans dommage.
Future<void> _relaxPayerIdentity(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  const targets = <String, List<String>>{
    'payments': ['payer_first_name', 'payer_last_name'],
    'boutique_sales': ['payer_first_name', 'payer_last_name', 'payer_name'],
  };

  for (final entry in targets.entries) {
    final name = entry.key;
    if (!await _hasTable(db, name)) continue;

    // La reconstruction ne se déclenche que si la contrainte est encore là.
    final constrained = [
      for (final column in entry.value)
        if (await _isColumnNotNull(db, name, column)) column,
    ];
    if (constrained.isNotEmpty) {
      await _rebuildTableInPlace(db, schema, name, suffix: 'v42');
    }

    // Puis la normalisation, sur toutes les colonnes d'identité — y compris
    // celles qui étaient déjà nullables : `payer_name` accueillait le même
    // repli sans avoir jamais porté de `NOT NULL`.
    for (final column in entry.value) {
      if (!await _hasColumn(db, name, column)) continue;
      await db.execute(
        "UPDATE $name SET $column = NULL WHERE TRIM($column) = ''",
      );
    }
  }
}

/// La colonne existe-t-elle avec un `NOT NULL` ?
///
/// Lu du PRAGMA plutôt que du DDL : c'est la forme RÉELLE de la table sur cette
/// tablette-là, la seule chose qu'un palier rejouable ait le droit de croire.
Future<bool> _isColumnNotNull(
  DatabaseExecutor db,
  String table,
  String column,
) async {
  for (final info in await db.rawQuery('PRAGMA table_info($table)')) {
    if (info['name'] == column) return (info['notnull'] as int? ?? 0) == 1;
  }
  return false;
}

/// Reconstruit [name] sur sa forme d'aujourd'hui, en recopiant les colonnes
/// **communes aux deux formes**.
///
/// Un `SELECT` d'une colonne que la table source n'a pas ferait lever la
/// migration ; une colonne que la nouvelle forme n'a plus n'a rien à recevoir.
/// L'intersection est donc la seule liste sûre — et c'est exactement ce que
/// font déjà les étapes v33/v34.
Future<void> _rebuildTableInPlace(
  DatabaseExecutor db,
  List<TableSchema> schema,
  String name, {
  required String suffix,
}) async {
  final table = schema.firstWhere((t) => t.name == name);
  final sourceColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($name)'))
      c['name'] as String,
  };
  await db.execute('ALTER TABLE $name RENAME TO ${name}_$suffix');
  await db.execute(table.createTableSql);
  final targetColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($name)'))
      c['name'] as String,
  };
  final columnList = targetColumns.where(sourceColumns.contains).join(', ');
  if (columnList.isNotEmpty) {
    await db.execute(
      'INSERT INTO $name ($columnList) SELECT $columnList FROM ${name}_$suffix',
    );
  }
  await db.execute('DROP TABLE ${name}_$suffix');
  for (final indexSql in table.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }
}

/// Étape v37 : les deux tables du barème refaites sans `id`, et `value` renommée
/// `percentage`.
///
/// **Refaites, pas migrées.** Ce sont des tables de cache référentiel : le pull
/// du bundle les réécrit en entier, école par école, et rien d'autre ne les
/// alimente. Recopier trois colonnes pour les faire écraser au prochain pull
/// coûterait plus que la ligne qu'on économise. Aucune base de terrain n'a
/// jamais porté la v36 — ce palier ne rattrape que les tablettes qui ont fait
/// tourner la branche, et la seule conséquence y est un barème absent jusqu'au
/// pull suivant.
///
/// Rejouable : se garde sur la forme réelle. La colonne `id` est la signature
/// de la v36 ; sur une table déjà refaite, il n'y a rien à faire.
Future<void> _rebuildReductionCatalog(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  for (final name in const ['ref_reduction_types', 'ref_reduction_lines']) {
    if (!await _hasTable(db, name)) continue;
    if (!await _hasColumn(db, name, 'id')) continue;
    await db.execute('DROP TABLE $name');
    final table = schema.firstWhere((t) => t.name == name);
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
}

/// Étape v35 : `boutique_sale_lines.currency`, et `boutique_sales` sans montant.
///
/// La colonne de ligne est **backfillée depuis la vente** : ces lignes ont été
/// encaissées dans la devise que la vente portait, et c'est la seule vérité
/// disponible. Sans backfill, un `NOT NULL` sur des lignes existantes ferait
/// échouer la montée sur une caisse qui a déjà vendu.
///
/// Rejouable : se garde sur la forme réelle des deux tables.
Future<void> _moveBoutiqueCurrencyToLines(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  const sales = 'boutique_sales';
  const lines = 'boutique_sale_lines';
  if (!await _hasTable(db, sales) || !await _hasTable(db, lines)) return;
  if (!await _hasColumn(db, sales, 'currency')) return;

  if (!await _hasColumn(db, lines, 'currency')) {
    // Défaut vide plutôt qu'une devise inventée : le backfill qui suit le
    // remplace par celle de la vente, et une ligne orpheline se lira « devise
    // inconnue » — jamais « dollars » par accident.
    await db.execute(
      "ALTER TABLE $lines ADD COLUMN currency TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'UPDATE $lines SET currency = ('
      'SELECT s.currency FROM $sales s WHERE s.id = $lines.sale_id'
      ') WHERE EXISTS ('
      'SELECT 1 FROM $sales s WHERE s.id = $lines.sale_id)',
    );
  }

  // La vente perd `total_in_cents` et `currency` : ils se dérivent des lignes.
  final table = schema.firstWhere((t) => t.name == sales);
  final sourceColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($sales)'))
      c['name'] as String,
  };
  await db.execute('ALTER TABLE $sales RENAME TO ${sales}_v34');
  await db.execute(table.createTableSql);
  final targetColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($sales)'))
      c['name'] as String,
  };
  final columnList = targetColumns.where(sourceColumns.contains).join(', ');
  if (columnList.isNotEmpty) {
    await db.execute(
      'INSERT INTO $sales ($columnList) SELECT $columnList FROM ${sales}_v34',
    );
  }
  await db.execute('DROP TABLE ${sales}_v34');
  for (final indexSql in table.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }
}

/// Étape v34 : retire `amount_in_cents` et `currency` de `payments`.
///
/// SQLite ne sait pas supprimer une colonne avant 3.35 : on reconstruit la table
/// et on recopie. **Les 23 colonnes de la forme v33, et elles seules** — la
/// table source porte la forme d'AVANT cette étape, et un `SELECT` d'une colonne
/// qu'elle n'a pas ferait lever la migration.
///
/// L'étape est rejouable : elle se garde sur la **forme réelle** de la table
/// plutôt que sur un drapeau, et ne fait rien si les colonnes sont déjà parties.
Future<void> _dropPaymentScalarAmounts(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  const name = 'payments';
  if (!await _hasTable(db, name)) return;
  if (!await _hasColumn(db, name, 'amount_in_cents')) return;

  // Les colonnes RÉELLEMENT présentes des deux côtés, jamais une liste figée.
  //
  // Une liste écrite à la main suppose que la table source a exactement la
  // forme d'avant cette étape. C'est faux dès qu'une base part de plus loin :
  // toutes les migrations tournent dans le même passage, et un test de palier
  // ancien crée une `payments` qui n'a ni `academic_year_id` ni la moitié du
  // reste. Le `SELECT` lève alors, et c'est toute la montée qui s'arrête — sur
  // une table qui porte de l'argent.
  //
  // L'intersection règle les deux sens : une colonne que la source n'a pas
  // reste à son défaut dans la table neuve, une colonne qu'elle a en trop est
  // ignorée.
  final table = schema.firstWhere((t) => t.name == name);
  final sourceColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($name)'))
      c['name'] as String,
  };
  // L'ancienne table emporte ses index en changeant de nom ; ils disparaissent
  // avec elle au DROP, ce qui laisse les noms libres pour les index canoniques
  // recréés en dernier.
  await db.execute('ALTER TABLE $name RENAME TO ${name}_v33');
  await db.execute(table.createTableSql);

  final targetColumns = {
    for (final c in await db.rawQuery('PRAGMA table_info($name)'))
      c['name'] as String,
  };
  final columnList = targetColumns.where(sourceColumns.contains).join(', ');
  if (columnList.isNotEmpty) {
    await db.execute(
      'INSERT INTO $name ($columnList) SELECT $columnList FROM ${name}_v33',
    );
  }
  await db.execute('DROP TABLE ${name}_v33');
  for (final indexSql in table.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }
}

/// Étape v22 : `editique_cache_entries.content_sha256` devient nullable.
///
/// SQLite ne sait pas relâcher un `NOT NULL` : il faut reconstruire la table.
/// On la reconstruit **avec copie**, jamais en la vidant — chaque ligne perdue
/// serait un fichier chiffré devenu introuvable, donc une pièce qu'un guichet
/// hors ligne ne pourrait plus ressortir. C'est exactement ce qu'un cache de
/// restitution existe pour éviter.
///
/// L'étape est rejouable : elle se garde sur la **forme réelle** de la colonne
/// (`PRAGMA table_info`) plutôt que sur un drapeau, et ne fait rien si le
/// relâchement est déjà en place.
Future<void> _relaxEditiqueCacheContentHash(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  const name = 'editique_cache_entries';
  if (!await _hasTable(db, name)) return;

  final columns = await db.rawQuery('PRAGMA table_info($name)');
  final hash = columns.where((c) => c['name'] == 'content_sha256');
  // Colonne absente (table d'une forme inattendue) ou déjà nullable : rien à
  // faire. `notnull` vaut 1 tant que la contrainte tient.
  if (hash.isEmpty || (hash.first['notnull'] as int? ?? 0) == 0) return;

  final table = schema.firstWhere((t) => t.name == name);
  // **Les 13 colonnes de la forme v21, et elles seules.** Ne jamais y ajouter
  // une colonne postérieure : la table source porte la forme d'AVANT cette
  // étape, et un `SELECT` d'une colonne qu'elle n'a pas ferait lever la
  // migration. Les colonnes plus récentes — `cancelled_at`,
  // `cancellation_reason` en v23 — existent bien dans la table reconstruite,
  // puisqu'elle naît du DDL canonique, et y restent simplement NULL : l'état
  // correct pour une pièce dont on ignore encore si elle a été retirée.
  const columnList =
      'id, document_id, document_number, doc_type, student_id, '
      'academic_year_id, school_id, owner_uid, size_bytes, content_sha256, '
      'emitted_at, created_at, last_accessed_at';

  // L'ancienne table emporte ses index en changeant de nom ; ils disparaissent
  // avec elle au DROP, ce qui laisse les noms libres pour les index canoniques
  // recréés en dernier.
  await db.execute('ALTER TABLE $name RENAME TO ${name}_v21');
  await db.execute(table.createTableSql);
  await db.execute(
    'INSERT INTO $name ($columnList) SELECT $columnList FROM ${name}_v21',
  );
  await db.execute('DROP TABLE ${name}_v21');
  for (final indexSql in table.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }
}

/// Étape v18 : `owner_uid` sur les tables de référence cadrées enseignant.
///
/// Deux traitements distincts, imposés par la nature des données :
///
/// - `ref_recurring_sessions` / `ref_cours` : simple `ALTER … ADD COLUMN`. Une
///   séance ou un cours n'appartient qu'à un enseignant, donc l'id reste une
///   clé primaire valide entre comptes.
/// - les 5 tables du bundle `grades-referential` : **recréées** avec une clé
///   primaire composite `(id, owner_uid)`. Ce sont des références d'ÉCOLE (les
///   branches, plafonds et périodes ont les mêmes ids pour tous les profs
///   d'un établissement) : avec l'id seul, le pull du second compte écraserait
///   les lignes du premier et lui volerait son `owner_uid`. SQLite ne sait pas
///   modifier une clé primaire — d'où le DROP/CREATE, sans risque : ces tables
///   sont 100 % dérivées de la synchro, rejouées intégralement au prochain pull.
///
/// Les lignes héritées sont purgées et les curseurs correspondants supprimés :
/// elles n'ont pas de propriétaire connaissable (la colonne n'existait pas), et
/// les laisser sous le repli `''` les rendrait invisibles au compte courant tout
/// en occupant leurs ids. Chaque device repart d'un bootstrap propre au prochain
/// passage online — même parti pris que les migrations v11 et v16.
Future<void> _addOwnerScopeToAcademicsRefTables(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  for (final name in const ['ref_recurring_sessions', 'ref_cours']) {
    if (!await _hasTable(db, name)) continue;
    if (!await _hasColumn(db, name, 'owner_uid')) {
      await db.execute(
        "ALTER TABLE $name ADD COLUMN owner_uid TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.delete(name);
  }
  // Index de lecture scopée, portés par la définition canonique des tables.
  for (final name in const ['ref_recurring_sessions', 'ref_cours']) {
    if (!await _hasTable(db, name)) continue;
    final table = schema.firstWhere((t) => t.name == name);
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }

  for (final name in const [
    'ref_branche',
    'ref_ligne_bareme',
    'ref_chapitre',
    'ref_periode',
    'ref_sous_periode',
  ]) {
    final table = schema.firstWhere((t) => t.name == name);
    await db.execute('DROP TABLE IF EXISTS $name');
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }

  // Curseurs des ressources repartitionnées : purgés sous leurs DEUX formes
  // (clé héritée non scopée `academics_cours`, et clé scopée `…@<uid>` que la
  // version précédente n'écrivait pas encore mais qu'un rejeu pourrait avoir
  // posée). Sans cette purge, la base est vide ET le prochain pull répond 304.
  if (await _hasTable(db, 'sync_meta')) {
    await db.delete(
      'sync_meta',
      where:
          "resource LIKE 'schedule_sessions%' "
          "OR resource LIKE 'academics_cours%' "
          "OR resource LIKE 'academics_grades_referential%'",
    );
  }
}

/// Migration v4 (Présence) : matérialise `attendance_sessions` + `session_id`,
/// puis **backfille une session rétroactive** par appel legacy déjà en base.
///
/// Sans ce backfill, les `attendance_records` créés en v1..v3 deviendraient des
/// exceptions orphelines, invisibles au modèle des 3 états (« pas de session »
/// serait lu « appel non fait » alors qu'un appel a bien eu lieu). Les sessions
/// backfillées sont marquées `SYNCED` (l'appel a déjà eu lieu, la resync le
/// réalignera par clé naturelle) et leur `id` est un uuid v4 **généré en SQL**
/// (aucune dépendance Dart → migration exerçable en ffi hors SQLCipher).
///
/// Enfin, les entrées d'outbox `ATTENDANCE` au format full-write obsolète sont
/// purgées : leur payload n'est plus décodable par le handler agrégat (A3), les
/// laisser en ferait des poison-entries. La donnée reste dans `attendance_records`.
Future<void> migrateAttendanceToSessionModel(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  // Base antérieure à la Présence (aucun appel local) : rien à migrer. Les
  // tables seront matérialisées par `onCreate` / le rejeu de schéma `<2`.
  if (!await _hasTable(db, 'attendance_records')) return;

  final sessionsTable = schema.firstWhere(
    (t) => t.name == 'attendance_sessions',
  );
  await db.execute(_asIfNotExists(sessionsTable.createTableSql));
  for (final indexSql in sessionsTable.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }

  // `attendance_records` existe déjà (v1) → ajout de la colonne + son index.
  if (!await _hasColumn(db, 'attendance_records', 'session_id')) {
    await db.execute(
      'ALTER TABLE attendance_records ADD COLUMN session_id TEXT',
    );
  }
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_attendance_session '
    'ON attendance_records(session_id)',
  );

  // Backfill : une session SYNCED par (classe, date, année) distinct des records.
  // uuid v4 forgé en SQL pur (RFC 4122 : version 4, variant 8/9/a/b).
  await db.execute('''
    INSERT INTO attendance_sessions
      (id, classroom_id, attendance_date, academic_year_id,
       updated_at, sync_status, synced_at)
    SELECT
      lower(
        hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
        substr(hex(randomblob(2)), 2) || '-' ||
        substr('89ab', abs(random()) % 4 + 1, 1) ||
        substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
      ),
      classroom_id, attendance_date, academic_year_id,
      MAX(updated_at), 'SYNCED', MAX(updated_at)
    FROM attendance_records
    WHERE session_id IS NULL
    GROUP BY classroom_id, attendance_date, academic_year_id
  ''');
  await db.execute('''
    UPDATE attendance_records
    SET session_id = (
      SELECT s.id FROM attendance_sessions s
      WHERE s.classroom_id = attendance_records.classroom_id
        AND s.attendance_date = attendance_records.attendance_date
        AND s.academic_year_id = attendance_records.academic_year_id
    )
    WHERE session_id IS NULL
  ''');

  // Purge des poison-entries d'outbox au format full-write (pré-1.2.0).
  await db.delete('outbox', where: "aggregate_type = 'ATTENDANCE'");
}

/// Vrai si [column] existe déjà sur [table] (via `PRAGMA table_info`). Rend le
/// `ALTER … ADD COLUMN` idempotent (SQLite le refuse si la colonne est présente).
Future<bool> _hasColumn(
  DatabaseExecutor db,
  String table,
  String column,
) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.any((row) => row['name'] == column);
}

/// Vrai si [table] existe dans la base (via `sqlite_master`).
Future<bool> _hasTable(DatabaseExecutor db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

/// Rend un `CREATE TABLE …` idempotent (`IF NOT EXISTS`) pour les migrations.
String _asIfNotExists(String createTableSql) =>
    createTableSql.replaceFirst('CREATE TABLE ', 'CREATE TABLE IF NOT EXISTS ');

/// Rend un `CREATE INDEX …` idempotent (`IF NOT EXISTS`) pour les migrations.
/// Couvre les DEUX formes, `CREATE INDEX` et `CREATE UNIQUE INDEX`.
///
/// La seconde a été introduite par la table des anomalies (v20). Ne traiter que
/// la première faisait lever le rejeu de **toutes** les migrations — la garde
/// d'idempotence sautait sur un seul index, et avec elle l'escalier entier.
String _indexAsIfNotExists(String createIndexSql) => createIndexSql
    .replaceFirst('CREATE UNIQUE INDEX ', 'CREATE UNIQUE INDEX IF NOT EXISTS ')
    .replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS ');
