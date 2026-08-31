import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Remap d'une créance provisoire (uuid local) vers l'id réel serveur, résolu
/// par (student_id, academic_year_id, fee_code, fee_tariff_id) — clé stable
/// (back FB-4).
///
/// **Partagé par les deux accusés** : celui d'un paiement (`FinancePaymentAckDao`)
/// et celui d'une inscription (`EnrollmentAckDao`), qui reçoivent tous deux des
/// créances autoritaires et heurtent donc la même jumelle. Une seule
/// implémentation : la règle qui décide de ce qu'on efface ne doit pas exister
/// en deux exemplaires susceptibles de diverger.
///
/// Quatre garde-fous money-grade sur la résolution de la jumelle :
///  - **scopée à l'année** : `fee_code` seul n'est PAS unique dans le temps
///    (TUITION existe chaque année). La base offline survit au rollover : sans
///    ce scope, l'ACK d'une créance 2025-26 renommerait la créance 2024-25 et
///    ré-imputerait ses paiements sur la nouvelle année.
///  - **jamais une créance SYNCED** : seule une jumelle non encore remontée
///    (PROVISIONAL / PENDING_SYNC) peut être dissoute. Une ligne autoritaire ne
///    doit jamais être détruite par une résolution approximative — au pire on
///    laisse un doublon visible, jamais une perte de données.
///  - **scopée au TARIF** dès que les deux côtés en portent un : un niveau porte
///    plusieurs lignes d'une même nature (un minerval en sept tranches), et le
///    semis local en matérialise une par ligne. Sans ce filtre, l'accusé d'UNE
///    tranche dissoudrait les six autres et ré-imputerait leurs versements sur
///    elle : six créances effacées d'un coup, et de l'argent déplacé de tranche.
///  - **une jumelle sans tarif reste candidate** : créance *ad hoc*, ou base
///    d'avant la grille en tranches — sa nature est tout ce qu'on sait d'elle,
///    et laisser survivre un doublon se lit comme un frais dû de plus.
///
/// [feeTariffId] est celui de la créance CANONIQUE. Omis, il est relu depuis la
/// ligne [realChargeId] quand elle est déjà en base — c'est le cas du remap
/// d'allocation, dont le contrat ne porte que la nature.
///
/// `academic_year_id` est comparé avec `IS` (null-safe). Une créance canonique
/// sans année ne dissout donc aucune jumelle *datée* : on préfère un doublon à
/// une destruction.
///
/// Pendant du `_dissolveProvisionalTwins` de `FinanceLedgerSyncDao` côté pull de
/// masse : même invariant, contexte d'accès différent (ici par créance dans la
/// transaction de l'accusé, là un index pré-calculé par lot).
Future<void> dissolveProvisionalTwins(
  DatabaseExecutor txn, {
  required String studentId,
  String? academicYearId,
  required String feeCode,
  String? feeTariffId,
  required String realChargeId,
}) async {
  // La canonique, en une lecture : son existence décide du sort des jumelles
  // (supprimées ou renommées), et sa ligne de grille décide de QUELLES jumelles
  // sont les siennes.
  final canonical = await txn.query(
    'student_charges',
    columns: ['id', 'fee_tariff_id'],
    where: 'id = ?',
    whereArgs: [realChargeId],
    limit: 1,
  );
  var realExists = canonical.isNotEmpty;
  final tariffId =
      feeTariffId ??
      (realExists ? canonical.first['fee_tariff_id'] as String? : null);

  // **Toutes** les jumelles, pas la première : `(student_id, année, fee_code)`
  // n'a aucune contrainte d'unicité et `initializeChargesForStudent` peut avoir
  // rejoué (crash, seconde passe de réinscription). Un `limit: 1` en dissoudrait
  // une et laisserait l'autre vivre à côté de la canonique — le frais serait
  // facturé deux fois. Même règle que `_pendingChargeIndex` côté pull de masse.
  //
  // ⚠️ `academic_year_id` est NULLABLE, et `null` doit rester DISTINCT de `''`
  // (cf. `_ChargeKey` dans `finance_ledger_sync_dao.dart`). La comparaison
  // null-safe est donc obligatoire — mais elle ne peut pas passer par un
  // paramètre lié : sqflite refuse `null` dans `whereArgs` (types admis : num,
  // String, Uint8List) et avertit qu'il LÈVERA dans une version future. On
  // branche donc le SQL au lieu de lier un `null`.
  //
  // ⚠️ Surtout PAS un `= ?` : `x = NULL` n'est jamais vrai en SQL, la requête ne
  // remonterait AUCUNE jumelle, en silence — le frais serait facturé deux fois,
  // exactement ce que cette fonction existe pour empêcher.
  final anneeClause = academicYearId == null
      ? 'academic_year_id IS NULL'
      : 'academic_year_id = ?';
  final tarifClause = tariffId == null
      ? ''
      : 'AND (fee_tariff_id IS NULL OR fee_tariff_id = ?) ';
  final twins = await txn.query(
    'student_charges',
    columns: ['id'],
    where:
        'student_id = ? AND fee_code = ? AND id != ? '
        '$tarifClause'
        'AND $anneeClause AND sync_status <> ?',
    whereArgs: [
      studentId,
      feeCode,
      realChargeId,
      ?tariffId,
      ?academicYearId,
      SyncState.synced.dbValue,
    ],
  );
  if (twins.isEmpty) return;

  for (final row in twins) {
    final provId = row['id'] as String;
    // Les imputations suivent l'id serveur dans tous les cas.
    await txn.update(
      'payment_allocations',
      {'student_charge_id': realChargeId},
      where: 'student_charge_id = ?',
      whereArgs: [provId],
    );
    if (realExists) {
      await txn.delete('student_charges', where: 'id = ?', whereArgs: [provId]);
    } else {
      // La canonique n'existe pas encore : on renomme la PREMIÈRE jumelle pour
      // préserver la ligne, les suivantes sont alors des doublons purs. On ne la
      // marque PAS SYNCED — un remap déplace un id, il ne constate pas une
      // autorité ; c'est l'UPSERT autoritaire qui apporte soldes ET état.
      await txn.update(
        'student_charges',
        {'id': realChargeId},
        where: 'id = ?',
        whereArgs: [provId],
      );
      realExists = true;
    }
  }
}
