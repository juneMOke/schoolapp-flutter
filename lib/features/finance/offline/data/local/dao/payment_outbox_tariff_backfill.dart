import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';

/// Ce que la reprise a trouvé — et ce qu'elle n'a pas su désigner.
class TariffBackfillReport {
  /// Payloads réécrits avec au moins une ligne de grille retrouvée.
  final int payloadsEnriched;

  /// Entrées bloquées qui repartent, parce que leur payload a changé.
  final int entriesRequeued;

  /// Imputations qu'AUCUNE ligne locale ne désigne : ni la colonne de tarif, ni
  /// la créance qu'elles pointent. C'est le chiffre de l'arbitrage A — il
  /// décide entre un message dans la feuille de reprise et un geste de
  /// re-désignation au guichet. Écrire l'écran avant de le connaître, c'est
  /// écrire un écran pour zéro entrée.
  final int allocationsUnmatched;

  const TariffBackfillReport({
    this.payloadsEnriched = 0,
    this.entriesRequeued = 0,
    this.allocationsUnmatched = 0,
  });
}

/// Renseigne la ligne de grille sur les versements DÉJÀ en file.
///
/// Les payloads scellés avant la v38 n'ont pas de `feeTariffId`. Depuis que le
/// serveur admet plusieurs lignes d'une même nature sur un niveau, il refuse
/// d'imputer au hasard : ces versements repartiraient en 422
/// `AMBIGUOUS_FEE_CODE` **indéfiniment**. Ce sont des encaissements réels, avec
/// des reçus déjà imprimés — un `requeue` sans correction du payload renvoie le
/// même appel au même refus.
///
/// **Une reprise de DONNÉES, pas un palier de schéma** : elle lit le
/// grand-livre, qui doit déjà être juste (le semis matérialise une créance par
/// ligne de grille, l'accusé d'inscription les remplace), et elle doit pouvoir
/// se rejouer seule. Elle est donc idempotente par construction : une
/// allocation qui porte déjà un tarif n'est pas relue, un payload que rien n'a
/// enrichi n'est pas réécrit.
class PaymentOutboxTariffBackfill {
  final Database _db;

  const PaymentOutboxTariffBackfill(this._db);

  /// Parcourt les versements en file, **tous statuts confondus**.
  ///
  /// Les `PENDING` aussi : ils n'ont pas encore échoué, mais ils échoueront —
  /// attendre leur premier 422 pour les corriger ne ferait qu'ajouter un
  /// aller-retour et une ligne rouge dans la feuille de reprise.
  Future<TariffBackfillReport> run() async {
    final entries = await _db.query(
      OutboxDao.table,
      columns: ['id', 'payload'],
      where: 'aggregate_type = ?',
      whereArgs: ['PAYMENT'],
    );

    var enriched = 0;
    var requeued = 0;
    var unmatched = 0;

    for (final entry in entries) {
      final raw = entry['payload'];
      if (raw is! String) continue;

      // Le JSON est patché EN PLACE, jamais reconstruit depuis les modèles : un
      // aller-retour `fromJson().toJson()` normaliserait la forme à plat des
      // vieux payloads et perdrait au passage tout champ que le modèle du jour
      // ne connaît pas. Sur de l'argent déjà encaissé, on ne réécrit que ce
      // qu'on est venu écrire.
      final Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        payload = decoded;
      } on FormatException {
        continue; // payload illisible : la feuille de reprise le dira mieux
      }

      final allocations = payload['allocations'];
      if (allocations is! List) continue;

      var touched = false;
      for (final allocation in allocations) {
        if (allocation is! Map<String, dynamic>) continue;
        final existing = allocation['feeTariffId'];
        if (existing is String && existing.trim().isNotEmpty) continue;

        final allocationId = allocation['id'];
        final tariffId = allocationId is String
            ? await _resolveTariffId(allocationId)
            : null;
        if (tariffId == null) {
          unmatched++;
          continue;
        }
        allocation['feeTariffId'] = tariffId;
        touched = true;
      }

      if (!touched) continue;

      await _db.update(
        OutboxDao.table,
        {'payload': jsonEncode(payload)},
        where: 'id = ?',
        whereArgs: [entry['id']],
      );
      enriched++;

      // Le payload d'abord, la remise en file ensuite — jamais l'inverse : une
      // entrée relancée sur son payload d'origine retrouve le même refus.
      //
      // `requeue` ne touche que les `SYNC_ERROR` (sa propre clause) : une entrée
      // `PENDING` corrigée repart d'elle-même au prochain flush, sans qu'on
      // remette son compteur de tentatives à zéro.
      if (await OutboxDao(_db).requeue(entry['id'] as String) > 0) requeued++;
    }

    return TariffBackfillReport(
      payloadsEnriched: enriched,
      entriesRequeued: requeued,
      allocationsUnmatched: unmatched,
    );
  }

  /// La ligne de grille d'une imputation, par son id — **la seule clé stable**.
  ///
  /// Pas par `studentChargeId` : le payload est figé, tandis que
  /// `payment_allocations.student_charge_id` bouge (le pull dissout les
  /// jumelles, l'accusé remappe). Apparier par lui raterait exactement les cas
  /// visés — les créances provisoires. L'id d'allocation, lui, ne bouge jamais,
  /// et il donne accès à la colonne de tarif comme au lien À JOUR.
  Future<String?> _resolveTariffId(String allocationId) async {
    final rows = await _db.query(
      'payment_allocations',
      columns: ['fee_tariff_id', 'student_charge_id'],
      where: 'id = ?',
      whereArgs: [allocationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final direct = rows.first['fee_tariff_id'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final chargeId = rows.first['student_charge_id'] as String?;
    if (chargeId == null) return null;

    final charge = await _db.query(
      'student_charges',
      columns: ['fee_tariff_id'],
      where: 'id = ?',
      whereArgs: [chargeId],
      limit: 1,
    );
    if (charge.isEmpty) return null;
    final resolved = charge.first['fee_tariff_id'] as String?;
    return (resolved == null || resolved.isEmpty) ? null : resolved;
  }
}
