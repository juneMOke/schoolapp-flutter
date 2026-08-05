import 'package:school_app_flutter/core/database/table_schema.dart';

/// `editique_cache_entries` — **index** du cache de restitution éditique
/// (ADR-012 D-2/D-7, amendements AM-5 et AM-10).
///
/// ## Ce que cette table ne contient pas
///
/// Aucun octet. C'est sa raison d'être, pas une étape intermédiaire : les PDF
/// scellés vivent dans des **fichiers chiffrés hors base** (AES-GCM, clé en
/// secure storage), la base ne gardant que de quoi les retrouver, les mesurer
/// et les vérifier. Trois raisons, toutes vérifiées :
///
///  1. le `CursorWindow` d'Android est figé à 16 Ko par `sqlcipher-android` et
///     n'a aucun levier côté Dart. L'écriture d'un blob passe, la **relecture
///     lève** — le document est perdu, et le défaut est **invisible en
///     intégration continue**, qui tourne sur un moteur ffi sans CursorWindow ;
///  2. la connexion sqflite est unique et sérialise tout : un PDF de 120 Ko
///     entrerait en concurrence avec les lectures du guichet ;
///  3. l'effacement physique exigé par D-7 devient **démontrable** par
///     suppression de répertoire, ce que l'absence de pages libres dans un
///     fichier SQLite jamais compacté n'est pas.
///
/// Le nom du fichier se dérive de [id] — jamais du numéro de pièce, qui
/// afficherait le type et le rang du document en clair dans un listing de
/// répertoire.
///
/// ## Identité d'une entrée
///
/// `document_id` **ou** `document_number`, l'un des deux au moins, et non vide
/// (CHECK — une chaîne vide n'adresse rien de plus que `NULL`, et c'est ce
/// qu'un en-tête mal formé produit). Le
/// premier est la cible : aujourd'hui aucune émission ne rend d'identifiant
/// (rupture back R2), seul `payment.receiptId` en porte un, pour le reçu seul.
/// Le second est le repli best-effort, lu dans le `filename` du
/// `Content-Disposition` — en-tête que le contrat OpenAPI ne décrit pas et qui
/// peut donc manquer. Les deux sont uniques : `document_id` globalement, le
/// numéro **par école**. Une entrée indexée par numéro se verra remplir son
/// `document_id` le jour où le serveur l'expose (lot B2), sans perdre ni sa
/// place LRU ni son fichier.
///
/// ## Types admis
///
/// `AI`, `NP`, `RC`, `BU` — les pièces que le serveur **archive**. `RL` et `QT`
/// en sont exclus par contrainte SQL, et ce n'est pas un détail de périmètre :
/// le serveur les décrit « timestamped (not archived) » et ne les conserve pas.
/// Une copie locale serait donc l'**unique** exemplaire, et l'éviction LRU la
/// détruirait définitivement — ce qui retirerait à cette table la seule
/// propriété qui rend l'éviction acceptable (« un document évincé reste
/// re-téléchargeable en ligne »). `BU` y figure alors que le front ne sait pas
/// l'émettre : le bulletin est scellé en ligne côté serveur et n'atteindra ce
/// cache que par le pull du lot L3.4.
///
/// ## Portées, et pourquoi elles diffèrent
///
/// - `school_id` — **portée de lecture et d'effacement**. Une réaffectation de
///   tablette à une autre école efface physiquement les entrées de l'école
///   précédente (D-7, RG-012-21) ;
/// - `owner_uid` — **provenance**, jamais un filtre de lecture. Une pièce est
///   un document d'établissement : deux agents du même guichet doivent partager
///   la même copie plutôt qu'en cacher deux. La colonne sert à purger sur
///   changement de compte si le lot L3.6 le décide, pas à cloisonner ;
/// - `academic_year_id` — clé de **scope et de mesure** (`SUM(size_bytes)` par
///   année, sans lire un octet), et de libération manuelle éventuelle. **Jamais
///   un déclencheur de purge** : la purge calendaire est supprimée (AM-8), sa
///   falaise tomberait au 1er septembre, pendant les réinscriptions, seul
///   moment où l'établissement ressort massivement les pièces N-1.
///
/// ## Trois dates, qui ne disent pas la même chose
///
/// `emitted_at` est la date d'émission côté serveur, `created_at` celle de la
/// mise en cache, `last_accessed_at` celle du dernier accès. Les confondre
/// serait une faute visible : un bulletin de juin descendu par la synchro de
/// septembre s'afficherait en tête d'une liste censée être chronologique, et le
/// classement LRU se ferait sur l'ancienneté de la pièce au lieu de son usage.
/// `emitted_at` est nullable — le régime opportuniste ne la connaît pas
/// toujours, seul le listing serveur (lot B1) la rend.
///
/// Aucune clé étrangère vers `students` ou `ref_academic_years` : une pièce
/// peut être mise en cache pour un élève dont la ligne locale n'a pas encore
/// été pullée, et une contrainte ferait échouer l'écriture au pire moment.
const TableSchema editiqueCacheEntriesTable = TableSchema(
  name: 'editique_cache_entries',
  createTableSql: '''
    CREATE TABLE editique_cache_entries (
      id TEXT PRIMARY KEY,
      document_id TEXT,
      document_number TEXT,
      doc_type TEXT NOT NULL,
      student_id TEXT,
      academic_year_id TEXT,
      school_id TEXT NOT NULL,
      owner_uid TEXT NOT NULL DEFAULT '',
      size_bytes INTEGER NOT NULL,
      content_sha256 TEXT NOT NULL,
      emitted_at INTEGER,
      created_at INTEGER NOT NULL,
      last_accessed_at INTEGER NOT NULL,
      CHECK (
        COALESCE(NULLIF(document_id, ''), NULLIF(document_number, ''))
          IS NOT NULL
      ),
      CHECK (doc_type IN ('AI', 'NP', 'RC', 'BU'))
    )
  ''',
  createIndexSql: [
    // SQLite considère deux NULL comme distincts : les entrées encore sans
    // identifiant serveur (régime AM-5) coexistent sans se gêner, et deux
    // entrées portant le MÊME identifiant restent impossibles.
    'CREATE UNIQUE INDEX idx_editique_cache_document '
        'ON editique_cache_entries(document_id)',
    'CREATE UNIQUE INDEX idx_editique_cache_number '
        'ON editique_cache_entries(school_id, document_number)',
    // Miroir de l'index serveur `idx_editique_documents_subject` : la question
    // posée est la même des deux côtés (les pièces d'un élève, éventuellement
    // sur une année).
    'CREATE INDEX idx_editique_cache_subject '
        'ON editique_cache_entries(school_id, student_id, academic_year_id, '
        'doc_type)',
    // Balayage d'éviction. Volontairement NON scopé par école : le budget est
    // une propriété du **disque de la tablette**, pas d'un établissement.
    'CREATE INDEX idx_editique_cache_lru '
        'ON editique_cache_entries(last_accessed_at)',
  ],
);

/// Tables de la branche offline Éditique (ADR-012).
const List<TableSchema> editiqueOfflineTables = [editiqueCacheEntriesTable];
