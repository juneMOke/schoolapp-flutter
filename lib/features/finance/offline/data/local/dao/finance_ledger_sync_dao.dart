import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

/// Clé métier d'une créance : `(élève, année, poste)`. `fee_code` n'est unique
/// que DANS une année.
///
/// Un **record**, pas une chaîne jointe : l'égalité est structurelle, donc
/// aucun délimiteur à choisir (un `studentId` contenant le séparateur ne peut
/// pas provoquer de collision) et `null` reste distinct de `''` — la même
/// sémantique que le `academic_year_id IS ?` du SQL, alors qu'un
/// `'$a|${year ?? ''}|$c'` les confondait.
typedef _ChargeKey = (String studentId, String? academicYearId, String feeCode);

/// Application du miroir autoritaire du pull de masse (FF2) : grille tarifaire
/// scopée par année + upsert du grand-livre (créances, paiements, allocations),
/// avec dissolution des jumelles PROVISIONAL avant chaque créance canonique.
class FinanceLedgerSyncDao {
  final Database _db;

  const FinanceLedgerSyncDao(this._db);

  /// Taille de lot des purges `id IN (...)` — bornée bien en-deçà de
  /// `SQLITE_MAX_VARIABLE_NUMBER` (999 sur les SQLite anciens d'Android 10).
  static const int _deleteChunkSize = 500;

  /// Remplace la grille tarifaire des années couvertes par le bundle
  /// référentiel (snapshot **scopé**) : purge les lignes de ces années
  /// absentes du nouveau bundle (un tarif supprimé côté serveur ne doit pas
  /// rester fantôme — money-grade), puis upsert. Les tarifs d'autres années
  /// ne sont pas touchés ; sans année fournie, aucune purge (upsert seul).
  Future<void> replaceTariffsForYears(
    List<FeeTariffLocalModel> tariffs, {
    required List<String> academicYearIds,
  }) async {
    await _db.transaction((txn) async {
      if (academicYearIds.isNotEmpty) {
        // Diff calculé en Dart puis purge par lots bornés : on NE lie PAS un `?`
        // par tarif conservé. Un `id NOT IN (…)` non borné dépasse
        // SQLITE_MAX_VARIABLE_NUMBER dès qu'une grille compte >~999 lignes (cf.
        // revue #21) et **fige alors le curseur référentiel** (l'apply lève →
        // curseur non avancé → re-pull en boucle). Les années scopées sont peu
        // nombreuses (bundle année active) → leur `IN (…)` reste petit.
        final years = List.filled(academicYearIds.length, '?').join(', ');
        final existing = await txn.query(
          'ref_fee_tariffs',
          columns: ['id'],
          where: 'academic_year_id IN ($years)',
          whereArgs: academicYearIds,
        );
        final keepIds = {for (final t in tariffs) t.id};
        final staleIds = [
          for (final r in existing)
            if (!keepIds.contains(r['id'] as String)) r['id'] as String,
        ];
        for (var i = 0; i < staleIds.length; i += _deleteChunkSize) {
          final end = i + _deleteChunkSize < staleIds.length
              ? i + _deleteChunkSize
              : staleIds.length;
          final chunk = staleIds.sublist(i, end);
          await txn.delete(
            'ref_fee_tariffs',
            where: 'id IN (${List.filled(chunk.length, '?').join(', ')})',
            whereArgs: chunk,
          );
        }
      }
      final batch = txn.batch();
      for (final t in tariffs) {
        batch.insert(
          'ref_fee_tariffs',
          t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Applique le miroir autoritaire du pull. Découpage en lots (verrou relâché
  /// entre les lots) — grand-livre potentiellement volumineux ; upserts
  /// idempotents → apply partielle sûre. L'ordre n'est pas porteur : le reste se
  /// compose à la lecture, aucun solde n'est recalculé ici (FRONT §5/§8).
  ///
  /// Deux règles money-grade portées ici :
  ///  - **patch, pas REPLACE**, sur les lignes déjà connues : le pull n'est
  ///    autoritaire que sur les colonnes qu'il porte (cf. `toPullPatch`) — il ne
  ///    doit jamais écraser le payeur ni le libellé saisis au guichet ;
  ///  - **dissolution de la jumelle PROVISIONAL** avant d'insérer une créance
  ///    canonique, sinon l'élève est facturé deux fois (cf.
  ///    [_dissolveProvisionalTwins]).
  Future<void> upsertLedger({
    List<StudentChargeLocalModel> charges = const [],
    List<PaymentLocalModel> payments = const [],
    List<PaymentAllocationLocalModel> allocations = const [],
  }) async {
    await applyInBatches(
      _db,
      payments,
      apply: (txn, chunk) async {
        for (final p in chunk) {
          final patched = await txn.update(
            'payments',
            p.toPullPatch(),
            where: 'id = ?',
            whereArgs: [p.id],
          );
          if (patched == 0) {
            await txn.insert(
              'payments',
              p.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      },
    );
    await applyInBatches(
      _db,
      allocations,
      apply: (txn, chunk) async {
        for (final a in chunk) {
          final patched = await txn.update(
            'payment_allocations',
            a.toPullPatch(),
            where: 'id = ?',
            whereArgs: [a.id],
          );
          if (patched == 0) {
            await txn.insert(
              'payment_allocations',
              a.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      },
    );

    await applyInBatches(
      _db,
      charges,
      apply: (txn, chunk) async {
        // Index des jumelles candidates : une requête PAR LOT, dans la
        // transaction du lot. Pas par créance (le pull en masse en porte des
        // milliers, les jumelles se comptent sur les doigts), mais pas une fois
        // pour tout le pull non plus : `applyInBatches` relâche volontairement
        // le verrou entre les lots, et un élève peut être inscrit hors-ligne
        // pendant ce temps. Un index pris avant la boucle ignorerait ses
        // créances toutes fraîches, qui survivraient à côté de la canonique →
        // frais facturé deux fois. On borne la péremption à un lot.
        final twins = await _pendingChargeIndex(txn);
        for (final c in chunk) {
          await _dissolveProvisionalTwins(txn, c, twins);
          await txn.insert(
            'student_charges',
            c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
  }

  /// (clé métier → **ids**) des créances encore NON remontées : les seules
  /// qu'une créance canonique peut légitimement dissoudre. Une ligne SYNCED est
  /// autoritaire et n'est jamais candidate.
  ///
  /// Une LISTE par clé, pas un id : rien ne garantit l'unicité de
  /// `(student_id, academic_year_id, fee_code)` — la table n'a pas de
  /// contrainte, et `initializeChargesForStudent` peut avoir tourné deux fois
  /// (rejeu après crash, seconde passe de réinscription). Un
  /// `Map<_ChargeKey, String>` écraserait silencieusement toutes les jumelles
  /// sauf la dernière : une seule serait dissoute, l'autre survivrait à côté de
  /// la canonique — le frais serait facturé deux fois.
  Future<Map<_ChargeKey, List<String>>> _pendingChargeIndex(
    DatabaseExecutor txn,
  ) async {
    final rows = await txn.query(
      'student_charges',
      columns: ['id', 'student_id', 'academic_year_id', 'fee_code'],
      where: 'sync_status <> ?',
      whereArgs: [SyncState.synced.dbValue],
    );
    final index = <_ChargeKey, List<String>>{};
    for (final r in rows) {
      final key = (
        r['student_id'] as String,
        r['academic_year_id'] as String?,
        r['fee_code'] as String,
      );
      (index[key] ??= <String>[]).add(r['id'] as String);
    }
    return index;
  }

  /// Dissout la jumelle PROVISIONAL d'une créance canonique : ses imputations
  /// sont repointées vers l'id serveur, puis la ligne locale disparaît.
  ///
  /// Sans cela, l'élève inscrit hors-ligne (créances à uuid local) puis re-tiré
  /// du serveur (ids canoniques) porterait **deux lignes par frais** —
  /// `student_charges` n'a aucune contrainte d'unicité sur
  /// `(student_id, academic_year_id, fee_code)` et `getChargesByStudent` ne
  /// filtre que sur l'élève : le parent semblerait devoir le double, KPI et
  /// soldes compris. C'est le pendant, côté pull de masse, de ce que
  /// `FinancePaymentAckDao._remapProvisionalCharge` fait à l'ACK.
  Future<void> _dissolveProvisionalTwins(
    DatabaseExecutor txn,
    StudentChargeLocalModel canonical,
    Map<_ChargeKey, List<String>> twins,
  ) async {
    final key = (
      canonical.studentId,
      canonical.academicYearId,
      canonical.feeCode,
    );
    final ids = twins[key];
    if (ids == null) return;
    for (final twinId in ids) {
      if (twinId == canonical.id) continue;
      await txn.update(
        'payment_allocations',
        {'student_charge_id': canonical.id},
        where: 'student_charge_id = ?',
        whereArgs: [twinId],
      );
      await txn.delete('student_charges', where: 'id = ?', whereArgs: [twinId]);
    }
    twins.remove(key); // dissoutes : ne pas les rejouer sur une page suivante
  }
}
