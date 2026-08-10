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
        migrateOfflineDatabase(db, oldVersion, schema),
  );
}

/// Étapes de migration idempotentes ordonnées, guardées par [oldVersion].
/// Extraite de `onUpgrade` pour être exerçable hors SQLCipher (tests ffi) :
/// le vrai opener est chiffré et non ouvrable en test.
Future<void> migrateOfflineDatabase(
  DatabaseExecutor db,
  int oldVersion,
  List<TableSchema> schema,
) async {
  if (oldVersion < 2) {
    // v2 — Inscription : ajout des tables de référence (cohorte RE,
    // préinscriptions, socle référentiel). On rejoue tout le schéma en
    // `IF NOT EXISTS` : les tables déjà présentes sont ignorées, seules les
    // nouvelles sont créées (aucune donnée existante n'est touchée).
    for (final table in schema) {
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
  if (oldVersion < 3) {
    // v3 — Inscription : `source_ref` sur `enrollments` (référence d'origine
    // du dossier, contrat agrégat : matricule RE / id de préinscription PRE).
    // Les bases v1/v2 ont déjà la table → ALTER.
    await db.execute('ALTER TABLE enrollments ADD COLUMN source_ref TEXT');
  }
  if (oldVersion < 4) {
    // v4 — Présence : passage au modèle SESSION-agrégat (contrat 1.2.0). La
    // racine d'agrégat `attendance_sessions` lève l'ambiguïté des 3 états, et
    // `attendance_records` gagne un lien logique `session_id`.
    await migrateAttendanceToSessionModel(db, schema);
  }
  if (oldVersion < 5) {
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
  if (oldVersion < 6) {
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
  if (oldVersion < 7) {
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
  if (oldVersion < 8) {
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
  if (oldVersion < 9) {
    // v9 — Notes / Cours : cache du squelette de notation par cours
    // (`ref_cours_notation`) : arbre période/sous-période + statut d'ouverture +
    // effectif, requis hors ligne au détail cours et à la garde de création.
    // Table neuve → aucun backfill.
    final table = schema.firstWhere((t) => t.name == 'ref_cours_notation');
    await db.execute(_asIfNotExists(table.createTableSql));
    for (final indexSql in table.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (oldVersion < 10) {
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
  if (oldVersion < 11) {
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
  if (oldVersion < 12) {
    // v12 — Notes / Cours : bundle `grades-referential` (ETag, cadré prof) —
    // 5 tables réf neuves (`ref_branche`, `ref_ligne_bareme`, `ref_chapitre`,
    // `ref_periode`, `ref_sous_periode`), remplacement d'ensemble à chaque
    // pull. Devient la SEULE source du statut de clôture ; le squelette
    // `ref_cours_notation` (v9, alimenté par un endpoint ONLINE réutilisé) est
    // retiré — sa table reste présente mais inerte, purgée ici. `evaluation`
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
    // profit du bundle : purge sa donnée (table conservée inerte, jamais
    // droppée — idiome constant de ce migrateur) + son curseur `sync_meta`
    // résiduel, pour ne rien laisser d'orphelin.
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
  if (oldVersion < 13) {
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
  if (oldVersion < 14) {
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
  if (oldVersion < 15) {
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
  if (oldVersion < 16) {
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
  if (oldVersion < 17) {
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
  if (oldVersion < 18) {
    // v18 — Notes / Cours : partition par COMPTE des caches de référence cadrés
    // enseignant (`owner_uid`, cf. `core/offline/owner_scope.dart`). Sur une
    // tablette partagée, ces tables et leurs curseurs `sync_meta` étaient
    // uniques alors que chaque prof reçoit un univers différent : le second
    // compte reprenait le curseur du premier, recevait un `304` et ne voyait
    // jamais ses propres séances/cours — tout en lisant ceux de l'autre.
    await _addOwnerScopeToAcademicsRefTables(db, schema);
  }
  if (oldVersion < 19) {
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
  if (oldVersion < 20) {
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
  if (oldVersion < 21) {
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
  if (oldVersion < 22) {
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
  if (oldVersion < 23) {
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
  if (oldVersion < 25) {
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
  if (oldVersion < 26) {
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
