import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

bool _ffiInitialized = false;

/// Ouvre une base sqflite en mémoire (ffi) avec le **schéma offline complet**
/// (`buildOfflineSchema()` : socle + tables de la branche Classe/Présence/Discipline).
/// À fermer en tearDown.
///
/// [noIsolate] : exécute les requêtes dans l'isolat courant au lieu de l'isolat
/// de travail ffi. **Obligatoire sous `testWidgets`** : le corps d'un test widget
/// tourne dans un `FakeAsync`, où aucun message de port ne peut être délivré —
/// une requête servie par l'isolat ffi ne se termine donc JAMAIS, la future du
/// verrou sqflite reste en attente et le test échoue sur « A Timer is still
/// pending ». Sans isolat, tout se résout en microtâches, que `pump()` draine.
Future<Database> openFullOfflineDb({bool noIsolate = false}) async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  // `singleInstance: false` : chaque appel ouvre une base `:memory:` INDÉPENDANTE
  // (sinon le cache d'instance renvoie la même base et `CREATE TABLE` échoue au
  // 2ᵉ setUp — « table outbox already exists »).
  final db =
      await (noIsolate ? databaseFactoryFfiNoIsolate : databaseFactoryFfi)
          .openDatabase(
            inMemoryDatabasePath,
            options: OpenDatabaseOptions(singleInstance: false),
          );
  for (final table in buildOfflineSchema()) {
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}
