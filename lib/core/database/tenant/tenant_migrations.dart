import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/payment_corrections_schema.dart';
import 'package:school_app_flutter/core/database/schema/payroll_schema.dart';
import 'package:school_app_flutter/core/database/schema/staff_attendance_schema.dart';
import 'package:school_app_flutter/core/database/schema/staff_offline_schema.dart';
import 'package:school_app_flutter/core/database/table_schema.dart';

/// Escalier d'un fichier d'ÉCOLE (`school_<id>.db`).
///
/// Un fichier d'école neuf naît en v49 : il ne passe jamais par ici. Seule la
/// base héritée ADOPTÉE arrive en dessous — en v48, ou plus bas si le poste a
/// sauté des versions. Elle repasse alors par l'escalier hérité, sur le schéma
/// COMPLET (elle porte encore les tables de l'appareil), avant le palier v49.
///
/// Les paliers suivants d'une école s'ajoutent ici, `if (upTo(n))`, jamais
/// dans l'escalier hérité : celui-ci est clos à la v48.
Future<void> migrateTenantDatabase(
  DatabaseExecutor db,
  int oldVersion, {
  int newVersion = AppConstants.offlineDbSchemaVersion,
}) async {
  bool upTo(int version) => oldVersion < version && version <= newVersion;

  if (oldVersion < AppConstants.legacyOfflineDbSchemaVersion) {
    await migrateOfflineDatabase(
      db,
      oldVersion,
      buildOfflineSchema(),
      newVersion: AppConstants.legacyOfflineDbSchemaVersion,
    );
  }
  if (upTo(49)) {
    await _returnDeviceTables(db);
  }
  if (upTo(50)) {
    await _addTillPhone(db);
  }
  if (upTo(51)) {
    await _addAnnualMatriculationNumber(db);
  }
  if (upTo(52)) {
    await _expenseValidationCircuit(db);
  }
  if (upTo(53)) {
    await _addTicketCopies(db);
  }
  if (upTo(54)) {
    await _paymentCorrections(db);
  }
  if (upTo(55)) {
    await _createTables(db, staffOfflineTables);
  }
  if (upTo(56)) {
    await _createTables(db, staffAttendanceTables);
  }
  if (upTo(57)) {
    await _createTables(db, payrollTables);
  }
}

/// Escalier de `device.db`. Né en v49 : aucun palier en dessous, et les
/// suivants de l'appareil s'ajouteront ici.
Future<void> migrateDeviceDatabase(
  DatabaseExecutor db,
  int oldVersion, {
  int newVersion = AppConstants.offlineDbSchemaVersion,
}) async {}

/// v51 — `enrollments.annual_matriculation_number`.
///
/// Le matricule classique ne change jamais ; l'annuel reprend son préfixe et ses
/// six chiffres et **remplace l'année par le code catalogue du niveau** où
/// l'élève est inscrit cette année-là (`CF-2026-000018` en P4 →
/// `CF-P4-000018`). Il suit donc l'élève d'un niveau à l'autre.
///
/// ⚠️ **Il appartient à l'INSCRIPTION, pas à l'élève** — d'où cette colonne-ci
/// plutôt qu'une sur `students` : un élève à deux inscriptions en a deux, et
/// toute lecture est scopée à une année.
///
/// 🔴 **Ce n'est PAS une clé.** La séquence à six chiffres repart à 1 chaque
/// année civile : deux élèves d'un même niveau peuvent la partager. Jamais de
/// recherche, de déduplication ni de jointure dessus — le matricule classique
/// et les UUID restent les seuls identifiants. Aucun index ici, délibérément :
/// en poser un inviterait à s'en servir.
///
/// **Aucune reprise de données.** La colonne naît vide et se remplit par le
/// pull, au fil des inscriptions modifiées. La re-hydratation des inscriptions
/// déjà synchronisées est un geste SÉPARÉ, qui ne part qu'après le déploiement
/// serveur — cf. `MATRICULE_ANNUEL_PLAN.md` §11.1.
///
/// ⚠️ Garde de colonne, même raison qu'à la v50 : une base héritée adoptée
/// repasse par cet escalier.
Future<void> _addAnnualMatriculationNumber(DatabaseExecutor db) async {
  final info = await db.rawQuery('PRAGMA table_info(enrollments)');
  if (info.any((row) => row['name'] == 'annual_matriculation_number')) return;
  await db.execute(
    'ALTER TABLE enrollments ADD COLUMN annual_matriculation_number TEXT',
  );
}

/// v54 — la correction d'un versement : la table `payment_corrections`,
/// `payments.replaces_payment_id` et ce que le serveur dit d'une annulation
/// (`cancelled_by_name`, `cancellation_reason[_code]`,
/// `cancellation_cash_moved`) — plan « Correction d'un versement hors ligne ».
///
/// Création pure, **aucune reprise** : aucune correction n'existe avant ce
/// palier, et le lien de remplacement se remplit par le geste ou par le pull.
///
/// ⚠️ Gardes de table et de colonne, même raison qu'aux v50 et v53 : une base
/// héritée adoptée repasse par cet escalier, et une base sans `payments` le
/// traverse sans lever.
Future<void> _paymentCorrections(DatabaseExecutor db) async {
  await db.execute(
    paymentCorrectionsTable.createTableSql.replaceFirst(
      'CREATE TABLE payment_corrections',
      'CREATE TABLE IF NOT EXISTS payment_corrections',
    ),
  );
  for (final sql in kPaymentCorrectionsIndexSql) {
    await db.execute(_ifNotExists(sql));
  }
  final info = await db.rawQuery('PRAGMA table_info(payments)');
  if (info.isEmpty) return;
  const columns = {
    'replaces_payment_id': 'TEXT',
    // Ce que le serveur dit d'une annulation (B5) : qui, pourquoi, et si de
    // l'argent a changé de main. Lu pour l'écran, jamais pour un solde.
    'cancelled_by_name': 'TEXT',
    'cancellation_reason': 'TEXT',
    'cancellation_reason_code': 'TEXT',
    'cancellation_cash_moved': 'INTEGER',
  };
  final existing = {for (final row in info) row['name'] as String};
  for (final column in columns.entries) {
    if (existing.contains(column.key)) continue;
    await db.execute(
      'ALTER TABLE payments ADD COLUMN ${column.key} ${column.value}',
    );
  }
  await db.execute(_ifNotExists(kPaymentsReplacesIndexSql));
}

/// v55 — le fichier du personnel ; v56 — le Pointage du personnel ; v57 — la
/// Paie du personnel. Tables
/// neuves, création pure.
///
/// ⚠️ Gardes `IF NOT EXISTS`, même raison qu'à la v54 : une base héritée
/// adoptée repasse par cet escalier.
Future<void> _createTables(
  DatabaseExecutor db,
  List<TableSchema> tables,
) async {
  for (final table in tables) {
    await db.execute(
      table.createTableSql.replaceFirst(
        'CREATE TABLE ${table.name}',
        'CREATE TABLE IF NOT EXISTS ${table.name}',
      ),
    );
    for (final sql in table.createIndexSql) {
      await db.execute(_ifNotExists(sql));
    }
  }
}

String _ifNotExists(String createIndexSql) => createIndexSql.replaceFirstMapped(
  RegExp('^CREATE (UNIQUE )?INDEX '),
  (m) => 'CREATE ${m[1] ?? ''}INDEX IF NOT EXISTS ',
);

/// v53 — `ref_school.ticket_copies`, le nombre d'exemplaires d'un ticket que
/// le sélecteur d'imprimante propose d'office (`TICKET_COPIES_PLAN.md`, lot 2).
///
/// Même forme que la v50 : additif, facultatif, `null` tant que le serveur ne
/// le sert pas — le poste applique alors un exemplaire, comme avant. **Aucune
/// reprise** : le référentiel est renvoyé en entier à chaque pull.
///
/// ⚠️ Garde de colonne, même raison qu'à la v50 — et garde de TABLE : une base
/// qui n'a jamais porté le référentiel d'Inscription traverse le palier sans
/// lever, comme la v52 le fait pour une base sans registre des dépenses. Le
/// schéma vivant crée la colonne avec la table.
Future<void> _addTicketCopies(DatabaseExecutor db) async {
  final info = await db.rawQuery('PRAGMA table_info(ref_school)');
  if (info.isEmpty) return;
  if (info.any((row) => row['name'] == 'ticket_copies')) return;
  await db.execute('ALTER TABLE ref_school ADD COLUMN ticket_copies INTEGER');
}

/// v50 — `ref_school.till_phone`, le numéro de la CAISSE.
///
/// Distinct de `phone`, qui est le téléphone de l'établissement : sur le ticket
/// les deux s'impriment désormais en deux lignes nommées, « Tél. Promoteur » et
/// « Tél. caisse ». Un seul numéro nu laissait le parent deviner lequel appeler
/// pour une question de paiement.
///
/// Additif et facultatif des deux côtés : le champ arrive `null` tant que le
/// serveur ne le sert pas, et le gabarit tait une ligne vide. **Aucune reprise
/// de données** — le référentiel est renvoyé en ENTIER à chaque pull, donc la
/// colonne se remplit d'elle-même au prochain cycle, sans curseur à toucher.
///
/// ⚠️ Garde de colonne : SQLite refuse un `ADD COLUMN` sur une colonne
/// existante, et une base héritée adoptée repasse par cet escalier.
///
/// ⚠️ Ce numéro a été ATTRIBUÉ, pas réservé. Si un autre lot fusionne avant,
/// c'est celui qui fusionne en SECOND qui renumérote — la règle posée à la v47,
/// et le trou brûlé de la v24 dit pourquoi on ne réattribue jamais.
Future<void> _addTillPhone(DatabaseExecutor db) async {
  final info = await db.rawQuery('PRAGMA table_info(ref_school)');
  if (info.any((row) => row['name'] == 'till_phone')) return;
  await db.execute('ALTER TABLE ref_school ADD COLUMN till_phone TEXT');
}

/// v49 — la base adoptée rend à l'appareil ce qui lui appartient.
///
/// L'éclatement l'a déjà recopié dans `device.db` (MULTI_ECOLE_PLAN.md §10.3).
/// Le garder ici laisserait deux copies de la session diverger, et un DAO mal
/// câblé lirait la mauvaise sans que rien ne le signale.
///
/// DDL inline, jamais lu du schéma vivant. La session avant le compte : elle le
/// référence, et les clés étrangères sont actives.
Future<void> _returnDeviceTables(DatabaseExecutor db) async {
  await db.execute('DROP TABLE IF EXISTS auth_local_session');
  await db.execute('DROP TABLE IF EXISTS auth_local_user');
  await db.execute('DROP TABLE IF EXISTS editique_cache_entries');
  // Les curseurs du catalogue éditique sont partis avec son index ; le marqueur
  // d'école de sa garde n'a plus d'objet sous la coexistence.
  await db.execute(
    "DELETE FROM sync_meta WHERE resource = 'editique_cache_school' "
    "OR substr(resource, 1, 18) = 'editique_documents'",
  );
}

/// v52 — la dépense devient une **demande** soumise à décision.
///
/// Six colonnes portent la décision, la pression du demandeur et la fraîcheur
/// du fil ; une table neuve porte le fil lui-même. DDL inline, jamais lu du
/// schéma vivant ; chaque ajout est gardé pour que le palier se rejoue sans
/// dommage.
///
/// **Renommage défensif** des deux statuts de la V1 : le serveur a vérifié
/// qu'aucune dépense n'existe en base (D11 close), mais un `count(*)` distant
/// ne dit rien des bases locales des postes de développement — et une ligne
/// au statut inconnu se lirait « en attente » sur un écran qui la croirait
/// non décidée. `UNPAID` valait « engagée, reste à payer » : c'est
/// `APPROVED`. `PAID` ne bouge pas.
Future<void> _expenseValidationCircuit(DatabaseExecutor db) async {
  const columns = {
    'decided_by_id': 'TEXT',
    'decided_by_name': 'TEXT',
    'decided_at': 'TEXT',
    'decision_reason': 'TEXT',
    'reminder_count': 'INTEGER NOT NULL DEFAULT 0',
    'last_message_at': 'TEXT',
  };
  final existing = {
    for (final row in await db.rawQuery('PRAGMA table_info(expenses)'))
      row['name'] as String,
  };
  // Table absente : rien à monter, fil compris — une base sans registre des
  // dépenses n'a pas de demande à faire discuter.
  if (existing.isEmpty) return;
  for (final column in columns.entries) {
    if (existing.contains(column.key)) continue;
    await db.execute(
      'ALTER TABLE expenses ADD COLUMN ${column.key} ${column.value}',
    );
  }
  await db.execute(
    "UPDATE expenses SET status = 'APPROVED' WHERE status = 'UNPAID'",
  );
  await _expenseThread(db);
}

/// Le fil d'une demande — table neuve du palier 52.
///
/// Append-only, uuid client : c'est le patron du fil de la Discipline, sans
/// son défaut — la fraîcheur du fil vit dans `expenses.last_message_at`, pas
/// dans l'horloge d'arbitrage du contenu, et un message ne fera donc jamais
/// perdre une décision à l'arbitrage.
///
/// `IF NOT EXISTS` sur la table **et** sur son index : le palier se rejoue sur
/// une base déjà montée, et une base créée à neuf porte déjà les deux.
Future<void> _expenseThread(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_messages (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      expense_id TEXT NOT NULL,
      body TEXT NOT NULL,
      act TEXT,
      author_id TEXT,
      author_name TEXT,
      created_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC'
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_expense_messages_thread '
    'ON expense_messages(expense_id, created_at)',
  );
}
