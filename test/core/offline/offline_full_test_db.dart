import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

bool _ffiInitialized = false;

/// Ouvre une base sqflite en mémoire (ffi) avec le **schéma offline complet**
/// (`buildOfflineSchema()` : socle + tables de la branche Classe/Présence/Discipline).
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
