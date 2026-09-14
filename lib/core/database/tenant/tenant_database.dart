import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';

/// La base de l'école courante, derrière l'interface [Database]
/// (MULTI_ECOLE_PLAN.md, option C).
///
/// ## Pourquoi un proxy
///
/// Chaque école a son fichier SQLCipher, et aucun DAO ne le sait : ils
/// reçoivent tous `getIt<Database>()`, c'est-à-dire cette instance, qui délègue
/// au fichier attaché. Basculer d'école, c'est [attach]. Il n'y a aucun
/// `WHERE school_id` à écrire, donc aucun à oublier : deux écoles ne partagent
/// plus une seule ligne — plus un curseur, plus un `is_current`, plus un
/// `ref_school`.
///
/// ## Ce qu'il refuse
///
///  - **Sans école attachée**, tout accès échoue en
///    [NoTenantAttachedException].
///  - **Après une bascule**, tout accès d'un travail lié par [run] à l'école
///    précédente échoue en [StaleTenantException].
///
/// Une transaction déjà commencée finit sur le fichier où elle a commencé : le
/// `Transaction` qu'elle reçoit appartient au fichier, pas au proxy.
class TenantDatabase implements Database, TenantScope {
  /// Clé de zone portant l'époque à laquelle un travail a été lié. Une par
  /// instance : deux proxys (tests) ne se lisent pas l'un l'autre.
  final Object _epochKey = Object();

  Database? _database;
  String? _schoolId;

  /// Incrémentée à chaque attachement ET à chaque détachement. Un travail lié
  /// avant une déconnexion suivie d'une reconnexion à la MÊME école est périmé
  /// lui aussi : les jetons sous lesquels il est parti ne sont plus ceux de la
  /// session.
  int _epoch = 0;

  /// École attachée, ou `null`.
  String? get schoolId => _schoolId;

  /// Vrai si une école est attachée.
  bool get isAttached => _database != null;

  /// Attache [database], le fichier de [schoolId].
  void attach(String schoolId, Database database) {
    _database = database;
    _schoolId = schoolId;
    _epoch++;
  }

  /// Détache l'école courante.
  ///
  /// Le fichier n'est PAS fermé : une transaction déjà commencée dessus doit
  /// pouvoir se terminer, et la reconnexion suivante le retrouvera ouvert.
  void detach() {
    _database = null;
    _schoolId = null;
    _epoch++;
  }

  @override
  Future<T> run<T>(Future<T> Function() body) =>
      runZoned(body, zoneValues: {_epochKey: _epoch});

  @override
  bool get isStale {
    final bound = Zone.current[_epochKey];
    return bound != null && bound != _epoch;
  }

  Database get _current {
    if (isStale) throw const StaleTenantException();
    final database = _database;
    if (database == null) throw const NoTenantAttachedException();
    return database;
  }

  /// Résout le fichier DANS un corps asynchrone : un refus devient un `Future`
  /// en échec, jamais une exception levée à l'appel — qu'un appelant en
  /// `.then()` ou `catchError` laisserait sinon s'échapper.
  Future<R> _on<R>(Future<R> Function(Database db) operation) async =>
      operation(_current);

  // ── DatabaseExecutor ──────────────────────────────────────────────────────

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _on((db) => db.execute(sql, arguments));

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) =>
      _on((db) => db.rawInsert(sql, arguments));

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) => _on(
    (db) => db.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    ),
  );

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _on(
    (db) => db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => _on((db) => db.rawQuery(sql, arguments));

  @override
  Future<QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) => _on((db) => db.rawQueryCursor(sql, arguments, bufferSize: bufferSize));

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) => _on(
    (db) => db.queryCursor(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      bufferSize: bufferSize,
    ),
  );

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) =>
      _on((db) => db.rawUpdate(sql, arguments));

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) => _on(
    (db) => db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    ),
  );

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      _on((db) => db.rawDelete(sql, arguments));

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _on((db) => db.delete(table, where: where, whereArgs: whereArgs));

  @override
  Batch batch() => _current.batch();

  @override
  Database get database => this;

  // ── Database ──────────────────────────────────────────────────────────────

  @override
  String get path => _current.path;

  @override
  bool get isOpen => _database?.isOpen ?? false;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => _on((db) => db.transaction(action, exclusive: exclusive));

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) =>
      _on((db) => db.readTransaction(action));

  /// Le proxy ne se ferme pas : la session **détache**, et les fichiers
  /// restent ouverts pour la bascule suivante. Fermer ici laisserait la session
  /// rattacher un fichier fermé.
  @override
  Future<void> close() => throw UnsupportedError(
    'TenantDatabase ne se ferme pas : la session détache son école.',
  );

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) =>
      throw UnsupportedError('devInvokeMethod: réservé aux tests de sqflite');

  @override
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List<Object?>? arguments,
  ]) => throw UnsupportedError(
    'devInvokeSqlMethod: réservé aux tests de sqflite',
  );
}
