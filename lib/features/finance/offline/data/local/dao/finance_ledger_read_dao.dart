import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/generated_document_local_model.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/fee_tariff_scope.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Lectures du grand-livre Facturation (sqflite). Aucune écriture, aucune
/// transaction : le reste à payer se COMPOSE à la lecture, aucun solde stocké
/// n'est incrémenté (FRONT §5/§8).
class FinanceLedgerReadDao {
  final Database _db;

  const FinanceLedgerReadDao(this._db);

  /// Créances d'un élève avec le VRAI reste à payer, composé à la lecture
  /// (FRONT §5) : miroir serveur (`amount_paid`) + Σ des allocations des
  /// paiements de CE poste non encore remontés — `sync_status <> 'SYNCED'`, ce
  /// qui couvre PENDING_SYNC **ET** SYNC_ERROR (le cash d'un paiement en échec
  /// technique reste déduit → il ne réapparaît jamais « à payer »). Aucune
  /// colonne de solde stockée n'est lue : on dérive, on n'incrémente pas (§8).
  ///
  /// La ligne de grille est **nommée** au passage, par jointure sur la grille
  /// locale (v39) : sans son code, sept tranches de minerval s'affichent sept
  /// fois « Minerval ».
  ///
  /// ⚠️ **`LEFT JOIN`, jamais `JOIN`.** Une créance *ad hoc* n'a pas de tarif, et
  /// le tarif d'une créance ancienne peut avoir quitté l'appareil (grille
  /// caviardée sans `finance.grid.read`, année purgée par le pull). Une
  /// jointure stricte ferait alors disparaître des lignes du grand-livre pour un
  /// défaut d'affichage — sans commune mesure.
  ///
  /// La colonne jointe est préfixée `t_` : `sc.*` est relue par `fromMap`, et
  /// une colonne homonyme la masquerait silencieusement.
  ///
  /// **L'ordre : nature, puis ÉCHÉANCE, puis code, puis id.** Le tri ne portait
  /// que sur la nature — entre sept tranches d'un même minerval, il rendait donc
  /// l'ordre d'insertion de SQLite, et le guichet lisait « 3/3, 1/3, 2/3 ». Les
  /// nommer sans les ordonner n'aurait fait que déplacer le problème.
  ///
  /// L'échéance passe avant le code parce que c'est l'ordre dans lequel une
  /// famille paie. Elle est nullable et SQLite place les `NULL` en TÊTE : une
  /// tranche sans échéance serait remontée avant la première, d'où le
  /// `(… IS NULL) ASC` explicite. `sc.id` ferme le tri — arbitraire, mais
  /// **stable** : deux lectures rendent toujours la même page.
  ///
  /// ⚠️ Le code se trie lexicalement : « T10 » précéderait « T2 ». C'est
  /// acceptable ici parce que l'échéance a déjà tranché dans tous les cas
  /// réels — et un tri naturel coûterait plus qu'il ne rapporte tant qu'aucune
  /// école ne dépasse neuf tranches d'une même nature.
  Future<List<LocalStudentCharge>> getChargesByStudent(String studentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT sc.*,
             t.code AS t_fee_tariff_code,
             COALESCE((
               SELECT SUM(pa.amount_in_cents)
               FROM payment_allocations pa
               JOIN payments p ON p.id = pa.payment_id
               WHERE pa.student_charge_id = sc.id
                 AND p.sync_status <> ?
             ), 0) AS paid_pending
      FROM student_charges sc
      LEFT JOIN ref_fee_tariffs t ON t.id = sc.fee_tariff_id
      WHERE sc.student_id = ?
      ORDER BY sc.fee_code ASC,
               (sc.due_at IS NULL) ASC, sc.due_at ASC,
               (t.code IS NULL) ASC, t.code ASC,
               sc.id ASC
      ''',
      [SyncState.synced.dbValue, studentId],
    );
    return rows
        .map(
          (r) => StudentChargeLocalModel.fromMap(r).toEntity(
            paidPending: (r['paid_pending'] as int?) ?? 0,
            feeTariffCode: r['t_fee_tariff_code'] as String?,
          ),
        )
        .toList();
  }

  Future<List<LocalPayment>> getPaymentsByStudent(String studentId) async {
    final rows = await _db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'paid_at DESC',
    );
    if (rows.isEmpty) return const <LocalPayment>[];

    final amounts = await _amountsOfPayments([
      for (final r in rows) r['id'] as String,
    ]);
    return [
      for (final r in rows)
        PaymentLocalModel.fromMap(
          r,
        ).toEntity(amounts: amounts[r['id']] ?? MoneyBag.empty),
    ];
  }

  /// Ce que chaque versement a encaissé, **par devise**, dérivé de ses
  /// imputations.
  ///
  /// Le versement ne porte plus de montant à lui : ce n'en était pas une
  /// propriété, seulement un résumé de ses allocations. Une requête pour tout
  /// le lot plutôt qu'une par versement — N+1 requêtes sur une tablette se
  /// sentent.
  Future<Map<String, MoneyBag>> _amountsOfPayments(
    List<String> paymentIds,
  ) async {
    if (paymentIds.isEmpty) return const {};
    final placeholders = List.filled(paymentIds.length, '?').join(', ');
    final rows = await _db.rawQuery(
      'SELECT payment_id, currency, SUM(amount_in_cents) AS total '
      'FROM payment_allocations '
      'WHERE payment_id IN ($placeholders) '
      'GROUP BY payment_id, currency '
      'ORDER BY payment_id, currency',
      paymentIds,
    );
    final byPayment = <String, List<Money>>{};
    for (final r in rows) {
      (byPayment[r['payment_id'] as String] ??= <Money>[]).add(
        Money.parse(
          (r['total'] as int?) ?? 0,
          (r['currency'] as String?) ?? '',
        ),
      );
    }
    return {
      for (final entry in byPayment.entries)
        entry.key: MoneyBag.of(entry.value),
    };
  }

  /// Reçu (RC) d'un paiement, tel qu'il est connu **localement**.
  ///
  /// Le numéro vaut `PROV-…` tant que l'encaissement n'est pas synchronisé,
  /// puis le scellement à l'ACK le remplace par le `ETL-RC-…` définitif — d'où
  /// [LocalGeneratedDocument.isProvisional], qui dit à l'UI si le numéro
  /// affichable fait foi.
  ///
  /// `null` est un cas NORMAL et non une erreur : le scellement serveur est
  /// best-effort et hors transaction, et un paiement arrivé par pull depuis
  /// l'autre poste n'a jamais eu de ligne locale.
  Future<LocalGeneratedDocument?> getPaymentReceipt(String paymentId) async {
    final rows = await _db.query(
      'generated_documents',
      where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
      whereArgs: [paymentId, 'PAYMENT', 'RC'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GeneratedDocumentLocalModel.fromMap(rows.first).toEntity();
  }

  /// Imputations d'un paiement. Joint le paiement porteur pour replier **payeur**
  /// et **date** sur chaque ligne, exactement comme [getAllocationsByCharge] :
  /// les deux vues des imputations restent cohérentes (sinon cette voie
  /// afficherait « payeur inconnu / pas de date »). `payment_id` NOT NULL → le
  /// JOIN n'écarte aucune ligne ; colonnes du paiement préfixées `p_` pour ne
  /// pas masquer celles de `pa.*` lues par `fromMap`.
  ///
  /// L'ordre suit celui du grand-livre : nature, puis code de tranche, puis
  /// `pa.id` pour rester stable. L'échéance ne s'y invite pas — elle appartient
  /// à la créance, et cette répartition-ci est la **photo d'un versement**, dont
  /// les lignes n'ont d'ordre que celui qu'on leur donne.
  Future<List<LocalPaymentAllocation>> getAllocationsByPayment(
    String paymentId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.*,
             t.code              AS t_fee_tariff_code,
             p.paid_at           AS p_paid_at,
             p.payer_first_name  AS p_payer_first_name,
             p.payer_last_name   AS p_payer_last_name,
             p.payer_middle_name AS p_payer_middle_name,
             p.payer_phone_number AS p_payer_phone_number
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      LEFT JOIN ref_fee_tariffs t ON t.id = pa.fee_tariff_id
      WHERE pa.payment_id = ?
      ORDER BY pa.fee_code ASC,
               (t.code IS NULL) ASC, t.code ASC,
               pa.id ASC
      ''',
      [paymentId],
    );
    return rows
        .map(
          (r) => PaymentAllocationLocalModel.fromMap(r).toEntity(
            payerFirstName: r['p_payer_first_name'] as String?,
            payerLastName: r['p_payer_last_name'] as String?,
            payerMiddleName: r['p_payer_middle_name'] as String?,
            payerPhoneNumber: r['p_payer_phone_number'] as String?,
            paidAt: r['p_paid_at'] as String?,
            feeTariffCode: r['t_fee_tariff_code'] as String?,
          ),
        )
        .toList();
  }

  /// Imputations portant sur une créance (détail d'un frais, FRONT §4).
  ///
  /// Joint le paiement porteur pour replier le **payeur** et la **date** sur
  /// chaque ligne (détail d'un frais §16 : montant + payeur + date). Une
  /// imputation référence toujours un paiement (`payment_id` NOT NULL) → le JOIN
  /// n'écarte aucune ligne. Colonnes du paiement préfixées `p_` pour ne pas
  /// masquer celles de `pa.*` lues par `fromMap`.
  Future<List<LocalPaymentAllocation>> getAllocationsByCharge(
    String chargeId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.*,
             t.code              AS t_fee_tariff_code,
             p.paid_at           AS p_paid_at,
             p.payer_first_name  AS p_payer_first_name,
             p.payer_last_name   AS p_payer_last_name,
             p.payer_middle_name AS p_payer_middle_name,
             p.payer_phone_number AS p_payer_phone_number
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      LEFT JOIN ref_fee_tariffs t ON t.id = pa.fee_tariff_id
      WHERE pa.student_charge_id = ?
      ORDER BY p.paid_at DESC, pa.fee_code ASC
      ''',
      [chargeId],
    );
    return rows
        .map(
          (r) => PaymentAllocationLocalModel.fromMap(r).toEntity(
            payerFirstName: r['p_payer_first_name'] as String?,
            payerLastName: r['p_payer_last_name'] as String?,
            payerMiddleName: r['p_payer_middle_name'] as String?,
            payerPhoneNumber: r['p_payer_phone_number'] as String?,
            paidAt: r['p_paid_at'] as String?,
            feeTariffCode: r['t_fee_tariff_code'] as String?,
          ),
        )
        .toList();
  }

  Future<List<LocalFeeTariff>> getTariffsByLevel(String schoolLevelId) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      where: 'school_level_id = ?',
      whereArgs: [schoolLevelId],
    );
    return rows.map((r) => FeeTariffLocalModel.fromMap(r).toEntity()).toList();
  }

  /// Grille applicable à un niveau **sur une année** (Contrôle des frais).
  ///
  /// Contrairement à [getTariffsByLevel], qui ne connaît que le niveau exact,
  /// cette lecture applique le périmètre complet ([FeeTariffScope]) : tarifs de
  /// cycle inclus, année-ou-NULL. C'est le MÊME périmètre que celui qui a généré
  /// les créances — sans quoi l'écran offrirait un frais que personne ne doit.
  Future<List<LocalFeeTariff>> getTariffsForLevel({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      where: FeeTariffScope.whereClause(schoolLevelGroupId: schoolLevelGroupId),
      whereArgs: FeeTariffScope.whereArgs(
        schoolLevelId: schoolLevelId,
        academicYearId: academicYearId,
        schoolLevelGroupId: schoolLevelGroupId,
      ),
      orderBy: 'fee_code ASC',
    );
    return rows.map((r) => FeeTariffLocalModel.fromMap(r).toEntity()).toList();
  }

  /// Position des élèves [studentIds] sur le frais [feeCode] (Contrôle des
  /// frais) : attendu, miroir serveur et **payé en attente composé à la
  /// lecture** — mêmes règles que [getChargesByStudent], une seule requête.
  ///
  /// Le frais est joint par `fee_code` et non par `fee_tariff_id` : ce dernier
  /// est nullable au pull, alors que `fee_code` est l'invariant « unique dans
  /// une année » sur lequel repose déjà la génération des créances.
  ///
  /// `academic_year_id IS NULL` est inclus : une créance sans année appartient à
  /// toutes les années (cf. `LocalStudentCharge.belongsToYear`).
  ///
  /// Bornée par `student_id IN (…)` — l'index `idx_student_charges_student_fee`
  /// travaille, et aucun bump de schéma n'est nécessaire. Les identifiants sont
  /// envoyés par lots pour rester sous la limite de variables liées de SQLite.
  Future<List<LocalFeeChargeAggregate>> getFeeChargeAggregates({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  }) async {
    if (studentIds.isEmpty) return const <LocalFeeChargeAggregate>[];

    final aggregates = <LocalFeeChargeAggregate>[];
    for (var start = 0; start < studentIds.length; start += _idBatchSize) {
      final end = start + _idBatchSize < studentIds.length
          ? start + _idBatchSize
          : studentIds.length;
      final batch = studentIds.sublist(start, end);
      final placeholders = List.filled(batch.length, '?').join(', ');

      final rows = await _db.rawQuery(
        '''
        SELECT sc.student_id                    AS student_id,
               sc.currency                      AS currency,
               SUM(sc.expected_amount_in_cents) AS expected,
               SUM(sc.amount_paid_in_cents)     AS paid_mirror,
               SUM(COALESCE((
                 SELECT SUM(pa.amount_in_cents)
                 FROM payment_allocations pa
                 JOIN payments p ON p.id = pa.payment_id
                 WHERE pa.student_charge_id = sc.id
                   AND p.sync_status <> ?
               ), 0))                           AS paid_pending
        FROM student_charges sc
        WHERE sc.fee_code = ?
          AND (sc.academic_year_id = ? OR sc.academic_year_id IS NULL)
          AND sc.student_id IN ($placeholders)
        GROUP BY sc.student_id, sc.currency
        ORDER BY sc.student_id, sc.currency
        ''',
        [SyncState.synced.dbValue, feeCode, academicYearId, ...batch],
      );

      // Une LIGNE par (élève, devise) → une POSITION par devise, regroupées
      // sous l'élève. Le `GROUP BY` porte la devise depuis que le `MIN()` a
      // disparu : il étiquetait l'agrégat avec la devise la plus petite
      // alphabétiquement, choisie au hasard des données.
      final positionsByStudent = <String, List<FeeChargePosition>>{};
      for (final r in rows) {
        final studentId = r['student_id'] as String;
        (positionsByStudent[studentId] ??= <FeeChargePosition>[]).add(
          FeeChargePosition(
            currency: CurrencyCode.normalize((r['currency'] as String?) ?? ''),
            expectedInCents: (r['expected'] as int?) ?? 0,
            paidMirrorInCents: (r['paid_mirror'] as int?) ?? 0,
            paidPendingInCents: (r['paid_pending'] as int?) ?? 0,
          ),
        );
      }
      aggregates.addAll(
        positionsByStudent.entries.map(
          (entry) => LocalFeeChargeAggregate(
            studentId: entry.key,
            positions: entry.value,
          ),
        ),
      );
    }
    return aggregates;
  }

  /// Natures de frais **réellement facturées** sur l'année (tableau de bord du
  /// Contrôle des frais).
  ///
  /// Lues dans le grand-livre, et **non dans la grille tarifaire**, pour deux
  /// raisons qui vont dans le même sens. D'abord la grille peut ne pas être sur
  /// l'appareil — caviardée faute de `finance.grid.read`, ou simplement pas
  /// encore descendue — alors que les créances, elles, sont là : l'écran
  /// resterait vide en ayant tout ce qu'il faut pour répondre. Ensuite la
  /// population mesurée vient des créances : lister un frais que personne ne
  /// porte n'offrirait qu'une sélection qui ne rend rien.
  ///
  /// `academic_year_id IS NULL` est inclus : une créance sans année appartient à
  /// toutes les années (cf. `LocalStudentCharge.belongsToYear`).
  ///
  /// Rend des **codes de nature**, que l'appelant nomme par
  /// `localizedFeeLabel`. Surtout pas le `label` d'une ligne : l'écran est
  /// école-wide, deux niveaux portent le même `fee_code` sous des libellés
  /// différents, et en retenir un serait le choisir au hasard des données —
  /// le défaut du `MIN(currency)` déjà corrigé ici même.
  ///
  /// **Triées par nombre de créances, la plus portée en tête.** L'écran ouvre
  /// sur la première : un tableau de bord se lit, il ne se remplit pas. Un tri
  /// alphabétique le ferait ouvrir sur « ASSUR » — douze élèves — quand la
  /// question du matin porte sur le minerval. Le `fee_code` ferme le tri, pour
  /// que deux natures à égalité gardent un ordre **stable**.
  Future<List<String>> getFeeCodesForYear(String academicYearId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT fee_code, COUNT(*) AS charges
      FROM student_charges
      WHERE academic_year_id = ? OR academic_year_id IS NULL
      GROUP BY fee_code
      ORDER BY charges DESC, fee_code
      ''',
      [academicYearId],
    );
    return rows.map((r) => r['fee_code'] as String).toList(growable: false);
  }

  /// Position de **toute la population** sur un frais, ventilée par niveau
  /// (tableau de bord du Contrôle des frais).
  ///
  /// Même arithmétique que [getFeeChargeAggregates] — miroir serveur plus les
  /// allocations des paiements non encore remontés — mais la population n'est
  /// pas donnée : elle est **découverte**. D'où l'absence de `student_id IN (…)`,
  /// donc de lots d'identifiants, donc de liste à composer en amont.
  ///
  /// `GROUP BY` sur `(élève, niveau, devise)` :
  ///  - la **devise** parce qu'un `MIN()` étiquetterait l'agrégat de la devise
  ///    la plus petite alphabétiquement ;
  ///  - le **niveau** parce qu'un élève qui change de niveau en cours d'année
  ///    porte le même frais deux fois, et doit bel et bien à chacun. Il compte
  ///    donc dans les deux — ce qui garantit que le total de l'école reste la
  ///    somme de ses niveaux (FCD, D5). Cas rare, mais l'écrire évite qu'on
  ///    « corrige » un jour un écart qui n'en est pas un.
  ///
  /// [schoolLevelGroupId] borne au cycle. ⚠️ Le filtre est **ajouté au SQL**
  /// plutôt qu'écrit `(? IS NULL OR …)` : sqflite refuse `null` dans
  /// `whereArgs` et lèverait à l'exécution — le défaut latent connu de deux DAO
  /// voisins. Ici la clause n'existe que si le cycle existe.
  ///
  /// ⚠️ Aucun index ne couvre `fee_code` ni `school_level_id` : la requête
  /// scanne `student_charges`. C'est assumé — un index coûterait une migration,
  /// arbitrage déjà rendu pour cet écran — mais c'est à mesurer sur une base
  /// peuplée avant d'en dépendre. La sous-requête d'allocations, elle, s'appuie
  /// sur `idx_payment_allocations_charge`, qui existe.
  Future<List<LocalFeeLevelAggregate>> getFeeChargePositionsByLevel({
    required String academicYearId,
    required String feeCode,
    String? schoolLevelGroupId,
  }) async {
    final args = <Object>[
      SyncState.synced.dbValue,
      feeCode,
      academicYearId,
      ?schoolLevelGroupId,
    ];
    final cycleClause = schoolLevelGroupId == null
        ? ''
        : 'AND sc.school_level_group_id = ?';

    final rows = await _db.rawQuery('''
      SELECT sc.student_id                    AS student_id,
             sc.school_level_id               AS school_level_id,
             sc.currency                      AS currency,
             SUM(sc.expected_amount_in_cents) AS expected,
             SUM(sc.amount_paid_in_cents)     AS paid_mirror,
             SUM(COALESCE((
               SELECT SUM(pa.amount_in_cents)
               FROM payment_allocations pa
               JOIN payments p ON p.id = pa.payment_id
               WHERE pa.student_charge_id = sc.id
                 AND p.sync_status <> ?
             ), 0))                           AS paid_pending
      FROM student_charges sc
      WHERE sc.fee_code = ?
        AND (sc.academic_year_id = ? OR sc.academic_year_id IS NULL)
        $cycleClause
      GROUP BY sc.student_id, sc.school_level_id, sc.currency
      ORDER BY sc.student_id, sc.school_level_id, sc.currency
      ''', args);

    // Une LIGNE par (élève, niveau, devise) → un agrégat par (élève, niveau),
    // portant une position par devise. Deux Map imbriquées plutôt qu'une clé
    // concaténée : un identifiant n'a pas à promettre qu'il ne contient pas le
    // séparateur qu'on aurait choisi.
    final byStudent = <String, Map<String?, List<FeeChargePosition>>>{};
    for (final r in rows) {
      final studentId = r['student_id'] as String;
      final levelId = r['school_level_id'] as String?;
      final positions = (byStudent[studentId] ??= {})[levelId] ??=
          <FeeChargePosition>[];
      positions.add(
        FeeChargePosition(
          currency: CurrencyCode.normalize((r['currency'] as String?) ?? ''),
          expectedInCents: (r['expected'] as int?) ?? 0,
          paidMirrorInCents: (r['paid_mirror'] as int?) ?? 0,
          paidPendingInCents: (r['paid_pending'] as int?) ?? 0,
        ),
      );
    }

    return [
      for (final student in byStudent.entries)
        for (final level in student.value.entries)
          LocalFeeLevelAggregate(
            schoolLevelId: level.key,
            charge: LocalFeeChargeAggregate(
              studentId: student.key,
              positions: level.value,
            ),
          ),
    ];
  }

  /// Taille des lots d'identifiants. SQLite plafonne les variables liées d'une
  /// requête (999 par défaut) : on garde de la marge pour les 3 autres.
  static const int _idBatchSize = 500;
}
