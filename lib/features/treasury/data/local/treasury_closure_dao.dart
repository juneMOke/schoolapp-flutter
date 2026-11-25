import 'package:school_app_flutter/core/database/schema/treasury_schema.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/cash_closure_reader.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les clôtures de caisse descendues (`treasury_closures`), et le verrou
/// qu'elles posent sur les encaissements en espèces (R11).
class TreasuryClosureDao implements CashRegisterLock, CashClosureReader {
  final DatabaseExecutor _db;
  final CurrentUserContext _currentUser;
  final DateTime Function() _now;

  TreasuryClosureDao(this._db, this._currentUser, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static final String table = treasuryClosuresTable.name;

  /// L'horloge du DAO, en millisecondes : un appelant la lit **avant** une
  /// lecture en ligne pour dater ce qu'il recopiera ensuite.
  int nowMs() => _now().millisecondsSinceEpoch;

  /// Écrit une page du flux telle que le serveur la tient.
  ///
  /// **Monotone** : une clôture rouverte ne redevient jamais en vigueur (une
  /// reclôture est une autre clôture, un autre id). `reopened_at` garde donc
  /// la première valeur posée, d'où qu'elle vienne — une recopie partie avant
  /// la réouverture ne peut pas la défaire.
  Future<int> applyPulled(
    List<CashClosure> closures, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (closures.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final c in closures) {
      batch.rawInsert(
        'INSERT INTO $table (id, school_id, register_id, currency, cash_day, '
        'closed_at, reopened_at, synced_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET '
        'reopened_at = COALESCE($table.reopened_at, excluded.reopened_at), '
        'synced_at = excluded.synced_at',
        [
          c.id,
          schoolId,
          c.registerId,
          c.currency.code,
          TreasuryWire.dayParam(c.cashDay),
          c.closedAt.toUtc().toIso8601String(),
          c.reopenedAt?.toUtc().toIso8601String(),
          nowMs,
        ],
      );
    }
    await batch.commit(noResult: true);
    return closures.length;
  }

  /// Garde ce que cette tablette vient de faire (une clôture, une
  /// réouverture) : le verrou prend sans attendre le prochain tirage.
  Future<void> recordLocal(Iterable<CashClosure> closures) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;
    await applyPulled(
      closures.toList(growable: false),
      schoolId: schoolId,
      nowMs: nowMs(),
    );
  }

  /// Recopie la journée [day] lue en ligne, partie à [readStartedMs] : les
  /// clôtures en vigueur ([live]) et les caisses servies **ouvertes**
  /// ([openRegisterIds]) — une clôture que la tablette croyait en vigueur a été
  /// rouverte ailleurs, et le flux posera l'instant exact.
  ///
  /// Une ligne écrite **après** le départ de la lecture (un tirage du flux
  /// arrivé entre-temps) est plus fraîche qu'elle : on n'y touche pas.
  Future<void> recordRead(
    DateTime day, {
    required List<CashClosure> live,
    required List<String> openRegisterIds,
    required int readStartedMs,
  }) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;
    await applyPulled(live, schoolId: schoolId, nowMs: nowMs());
    if (openRegisterIds.isEmpty) return;
    await _db.update(
      table,
      {'reopened_at': _now().toUtc().toIso8601String()},
      where:
          'school_id = ? AND cash_day = ? AND reopened_at IS NULL '
          'AND synced_at < ? '
          'AND register_id IN '
          '(${List.filled(openRegisterIds.length, '?').join(', ')})',
      whereArgs: [
        schoolId,
        TreasuryWire.dayParam(day),
        readStartedMs,
        ...openRegisterIds,
      ],
    );
  }

  /// Les devises dont la caisse est close aujourd'hui, jour de caisse de
  /// l'école (un dimanche compte pour le lundi, comme côté serveur), et pas
  /// rouverte depuis.
  @override
  Future<Set<String>> closedToday() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return const {};
    final today = CashClosingRules.cashDayOf(SchoolTime.today(_now()));
    final rows = await _db.query(
      table,
      columns: ['currency'],
      where: 'school_id = ? AND cash_day = ? AND reopened_at IS NULL',
      whereArgs: [schoolId, TreasuryWire.dayParam(today)],
    );
    return {
      for (final row in rows)
        CurrencyCode.normalize(row['currency']! as String),
    };
  }

  @override
  Future<bool> hasLiveClosureFrom(DateTime day, String currency) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final rows = await _db.query(
      table,
      columns: ['id'],
      where:
          'school_id = ? AND UPPER(currency) = ? AND cash_day >= ? '
          'AND reopened_at IS NULL',
      whereArgs: [
        schoolId,
        CurrencyCode.normalize(currency),
        TreasuryWire.dayParam(day),
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
