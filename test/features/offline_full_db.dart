import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/table_schema.dart';

bool _ffiInitialized = false;

/// Ouvre une base sqflite en mémoire (ffi) avec TOUT le schéma offline
/// (`buildOfflineSchema()`) : socle + tables de la branche Inscription/Facturation.
/// À fermer en tearDown.
Future<Database> openFullOfflineDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  for (final table in buildOfflineSchema()) {
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

/// Ouvre un fichier temporaire DISTINCT portant le schéma [schema].
///
/// Sert à séparer la base de l'école et `device.db` comme en production :
/// `inMemoryDatabasePath` est partagé entre ouvertures, deux bases « en
/// mémoire » n'en feraient qu'une, et une jointure entre elles passerait.
Future<Database> _openSchemaFile(String name, List<TableSchema> schema) async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final dir = await Directory.systemTemp.createTemp('eteelo_$name');
  final db = await databaseFactoryFfi.openDatabase(
    '${dir.path}/$name.db',
    options: OpenDatabaseOptions(singleInstance: false),
  );
  for (final table in schema) {
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

/// Fichier d'école seul (`school_<id>.db`) : sans les tables de l'appareil.
Future<Database> openTenantTestDb() =>
    _openSchemaFile('school', buildTenantSchema());

/// `device.db` seul : le cache des pièces, sans aucune table de l'école.
Future<Database> openDeviceTestDb() =>
    _openSchemaFile('device', buildDeviceSchema());
