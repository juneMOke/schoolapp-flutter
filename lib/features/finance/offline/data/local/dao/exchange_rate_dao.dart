import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/exchange_rate_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le taux de guichet en local : écriture par le pull, lecture par le guichet.
///
/// **Aucune écriture ne vient d'ici** — un taux se paramètre côté direction, ce
/// DAO ne fait que recevoir et servir. Même régime que `ReductionCatalogDao`,
/// et pour la même raison : ces deux tables descendent à la **racine** du
/// bundle référentiel, hors slot d'année.
class ExchangeRateDao {
  final Database _db;

  const ExchangeRateDao(this._db);

  /// Remplace la série **de cette école** par celle du bundle : purge scopée
  /// puis insertion, en une transaction.
  ///
  /// ⚠️ **Scopé par école, jamais globalement.** La table n'a pas
  /// d'`academic_year_id` — une purge globale effacerait le taux de l'autre
  /// école sur une tablette partagée, et aucun filtre d'année ne viendrait
  /// masquer la perte : le poste d'à côté verrait sa bascule de devise
  /// s'éteindre sans rien qui l'explique.
  ///
  /// [schoolId] vide = appelant sans école résolue : on **ne touche à rien**.
  /// Purger sous la clé `''` effacerait la série d'une base héritée ; l'insérer
  /// sous cette clé la rendrait invisible à toute lecture scopée.
  Future<void> replaceForSchool(
    List<ExchangeRateLocalModel> rates, {
    required String schoolId,
  }) async {
    if (schoolId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(
        'ref_exchange_rates',
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
      final batch = txn.batch();
      for (final rate in rates) {
        batch.insert(
          'ref_exchange_rates',
          rate.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// La série de cette école, prête à être résolue par [ExchangeRates.at].
  ///
  /// La résolution « quel taux valait à `paidAt` » n'est **pas** ici : elle est
  /// pure, elle vit dans `core/money`, et un seul endroit doit la porter — la
  /// boutique en a besoin et ne peut pas importer finance.
  ///
  /// Les lignes inexploitables sont **écartées en silence** (cf.
  /// [ExchangeRateLocalModel.toEntity]) : une lecture ne remonte jamais
  /// d'erreur, et une série amputée éteint la bascule au guichet plutôt que de
  /// proposer un taux qu'on ne sait pas dater.
  Future<List<ExchangeRate>> ratesForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      'ref_exchange_rates',
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'base, quote, effective_from',
    );
    return [
      for (final row in rows) ?ExchangeRateLocalModel.fromMap(row).toEntity(),
    ];
  }
}
