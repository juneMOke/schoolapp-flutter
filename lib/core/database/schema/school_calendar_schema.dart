import 'package:school_app_flutter/core/database/table_schema.dart';

/// `cal_frameworks` — les cadres nationaux publiés des années de l'école,
/// descendus par `calendar.framework` : une ligne par cadre (une par année).
/// Chaque nouvelle version redescend la ligne entière, et ses éléments
/// remplacent tous ceux de l'année (`cal_framework_items`).
const TableSchema calFrameworksTable = TableSchema(
  name: 'cal_frameworks',
  createTableSql: '''
    CREATE TABLE cal_frameworks (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      year_label TEXT NOT NULL,
      version INTEGER NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      published_at TEXT,
      document_file_name TEXT,
      document_size_bytes INTEGER,
      document_uploaded_at TEXT,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_cal_frameworks_year ON cal_frameworks(school_id, year_label)',
  ],
);

/// `cal_framework_items` — les éléments d'un cadre national (périodes,
/// examens nationaux, congés, jours fériés, vie de l'école). `replaceable` :
/// l'école peut le remplacer (lu tel quel du cadre, v86).
const TableSchema calFrameworkItemsTable = TableSchema(
  name: 'cal_framework_items',
  createTableSql: '''
    CREATE TABLE cal_framework_items (
      id TEXT NOT NULL,
      framework_id TEXT NOT NULL,
      nature TEXT NOT NULL,
      title TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      scope TEXT NOT NULL,
      rhythm TEXT,
      period_order INTEGER,
      sub_period_order INTEGER,
      replaceable INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (framework_id, id)
    )
  ''',
);

/// `school_calendars` — les en-têtes des calendriers de l'école, descendus par
/// `calendar.calendars`. Un brouillon ne descend qu'à qui a un droit
/// d'écriture. `phase` est le témoin du serveur : l'écran recalcule (A3).
const TableSchema schoolCalendarsTable = TableSchema(
  name: 'school_calendars',
  createTableSql: '''
    CREATE TABLE school_calendars (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      year_label TEXT NOT NULL,
      status TEXT NOT NULL,
      phase TEXT,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      framework TEXT NOT NULL,
      framework_version INTEGER,
      published_at TEXT,
      published_by_name TEXT,
      published_by_role TEXT,
      updated_at TEXT,
      revision INTEGER NOT NULL DEFAULT 0,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_school_calendars_year '
        'ON school_calendars(school_id, year_label)',
  ],
);

/// `school_calendar_events` — les événements de l'école, descendus par
/// `calendar.events` et écrits sur l'appareil (dernier écrit gagne par
/// événement, `client_updated_at`).
///
/// - `deleted` : une suppression, envoyée puis gardée comme pierre tombale ;
/// - `sync_status` / `sync_error_code` : en attente, ou refusé avec son code ;
/// - `superseded_at` : un autre appareil a gagné, l'écran le signale une fois ;
/// - `replaces_item_id` : l'élément national que l'événement remplace (v86).
const TableSchema schoolCalendarEventsTable = TableSchema(
  name: 'school_calendar_events',
  createTableSql: '''
    CREATE TABLE school_calendar_events (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      calendar_id TEXT NOT NULL,
      nature TEXT NOT NULL,
      title TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      scope TEXT NOT NULL,
      note TEXT,
      to_verify INTEGER NOT NULL DEFAULT 0,
      created_by_name TEXT,
      created_by_role TEXT,
      replaces_item_id TEXT,
      client_updated_at INTEGER NOT NULL,
      server_updated_at INTEGER,
      deleted INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error_code TEXT,
      superseded_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_school_calendar_events_calendar '
        'ON school_calendar_events(calendar_id)',
    'CREATE INDEX idx_school_calendar_events_pending '
        'ON school_calendar_events(school_id, sync_status)',
  ],
);

const List<TableSchema> schoolCalendarTables = [
  calFrameworksTable,
  calFrameworkItemsTable,
  schoolCalendarsTable,
  schoolCalendarEventsTable,
];
