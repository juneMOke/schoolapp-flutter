import 'package:school_app_flutter/core/database/table_schema.dart';

/// `student_photos` — la photo de chaque élève, **sans ses octets**.
///
/// Une ligne par élève, miroir du flux `student.photos` : `sha256` est
/// l'empreinte de la photo que le serveur garde (`null` = pas de photo, ou
/// photo retirée), `taken_at` la date de prise qui arbitre deux envois.
///
/// Le geste local en attente d'envoi vit sur la même ligne (`pending_*`) :
/// une seule photo compte par élève, un nouveau geste remplace le précédent
/// comme son entrée d'outbox (`STUDENT_PHOTO:<élève>`). `sync_status` dit ce
/// que ce geste est devenu ; un geste refusé efface `pending_*` et garde la
/// raison dans `sync_error`.
///
/// `cached_96_sha` / `cached_512_sha` : l'empreinte de la photo dont les octets
/// sont déjà dans le magasin chiffré, par taille. Différente de `sha256`, la
/// copie est périmée et se retélécharge.
const TableSchema studentPhotosTable = TableSchema(
  name: 'student_photos',
  createTableSql: '''
    CREATE TABLE student_photos (
      student_id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      sha256 TEXT,
      taken_at TEXT,
      server_updated_at TEXT,
      pending_op TEXT,
      pending_sha256 TEXT,
      pending_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      cached_96_sha TEXT,
      cached_512_sha TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_student_photos_school ON student_photos(school_id)',
  ],
);

const List<TableSchema> studentPhotoTables = [studentPhotosTable];
