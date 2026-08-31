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
/// sémantique que le `academic_year_id IS NULL` du SQL, alors qu'un
/// `'$a|${year ?? ''}|$c'` les confondait.
///
/// ⚠️ Le SQL dit bien `IS NULL`, et jamais `= ?` avec un `null` lié : sqflite
/// refuse `null` dans `whereArgs`, et `x = NULL` ne serait de toute façon
/// jamais vrai.
typedef _ChargeKey = (String studentId, String? academicYearId, String feeCode);

/// Une créance encore non remontée, candidate à la dissolution : son id, et la
/// ligne de grille qu'elle porte.
///
/// Le tarif voyage avec l'id parce que la nature ne suffit plus à apparier une
/// provisoire et sa canonique : depuis que le serveur admet plusieurs lignes
/// d'une même nature sur un niveau, `(élève, année, fee_code)` désigne SEPT
/// créances là où il en désignait une.
typedef _PendingCharge = ({String id, String? feeTariffId});

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
  ///  - **paiements & allocations : patch, pas REPLACE** sur les lignes déjà
  ///    connues (`toPullPatch`) — le pull n'est autoritaire que sur les colonnes
  ///    qu'il porte, il ne doit jamais écraser le payeur ni le libellé saisis au
  ///    guichet. Les **créances**, elles, sont REPLACE'd (`toMap` complet) : le
  ///    pull EST la vérité du grand-livre et une créance ne porte aucune colonne
  ///    locale à préserver (`optimistic_paid_in_cents` est gelée/vestigiale, le
  ///    reste se compose à la lecture) — d'où l'insert `ConflictAlgorithm.replace`
  ///    ci-dessous, pas un patch ;
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

  /// (clé métier → **créances**) encore NON remontées : les seules qu'une
  /// créance canonique peut légitimement dissoudre. Une ligne SYNCED est
  /// autoritaire et n'est jamais candidate.
  ///
  /// Une LISTE par clé, pas une créance : rien ne garantit l'unicité de
  /// `(student_id, academic_year_id, fee_code)` — la table n'a pas de
  /// contrainte, `initializeChargesForStudent` peut avoir tourné deux fois
  /// (rejeu après crash, seconde passe de réinscription), et surtout un niveau
  /// porte désormais plusieurs tranches d'un même frais. Une `Map` à valeur
  /// unique écraserait silencieusement toutes les jumelles sauf la dernière :
  /// une seule serait dissoute, les autres survivraient à côté des canoniques —
  /// le frais serait facturé deux fois.
  Future<Map<_ChargeKey, List<_PendingCharge>>> _pendingChargeIndex(
    DatabaseExecutor txn,
  ) async {
    final rows = await txn.query(
      'student_charges',
      columns: [
        'id',
        'student_id',
        'academic_year_id',
        'fee_code',
        'fee_tariff_id',
      ],
      where: 'sync_status <> ?',
      whereArgs: [SyncState.synced.dbValue],
    );
    final index = <_ChargeKey, List<_PendingCharge>>{};
    for (final r in rows) {
      final key = (
        r['student_id'] as String,
        r['academic_year_id'] as String?,
        r['fee_code'] as String,
      );
      (index[key] ??= <_PendingCharge>[]).add((
        id: r['id'] as String,
        feeTariffId: r['fee_tariff_id'] as String?,
      ));
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
    Map<_ChargeKey, List<_PendingCharge>> twins,
  ) async {
    final key = (
      canonical.studentId,
      canonical.academicYearId,
      canonical.feeCode,
    );
    final candidates = twins[key];
    if (candidates == null) return;

    // La nature ouvre la porte, le TARIF désigne la jumelle. Sans ce filtre, la
    // première tranche du lot avalait les imputations des six autres : rien
    // n'était détruit, mais l'argent changeait de tranche — le parent voyait la
    // 1/7 soldée et la 5/7, qu'il venait de payer, toujours due.
    //
    // Une provisoire SANS tarif reste candidate : c'est une créance *ad hoc*, ou
    // une base d'avant la v38. Elle se fera avaler par la première canonique du
    // lot, faute de mieux — mais laisser survivre un doublon serait pire, il se
    // lit comme un frais dû de plus.
    final tariffId = canonical.feeTariffId;
    final dissolved = <_PendingCharge>[];
    for (final twin in candidates) {
      if (twin.id == canonical.id) continue;
      if (tariffId != null &&
          twin.feeTariffId != null &&
          twin.feeTariffId != tariffId) {
        continue; // une autre tranche du même frais : pas la nôtre
      }
      await txn.update(
        'payment_allocations',
        {'student_charge_id': canonical.id},
        where: 'student_charge_id = ?',
        whereArgs: [twin.id],
      );
      await txn.delete(
        'student_charges',
        where: 'id = ?',
        whereArgs: [twin.id],
      );
      dissolved.add(twin);
    }

    // Retirer les dissoutes SEULEMENT : les tranches voisines attendent encore
    // leur propre canonique, plus loin dans le même lot. Les oublier ici les
    // laisserait vivantes à côté d'elle — le doublon que cette méthode existe
    // pour empêcher. Et les rejouer serait pire : la deuxième dissolution
    // repointerait les imputations déjà déplacées vers une AUTRE tranche.
    candidates.removeWhere(dissolved.contains);
    if (candidates.isEmpty) twins.remove(key);
  }
}
