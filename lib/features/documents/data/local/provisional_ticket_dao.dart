import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/fee_tariff_code.dart';

/// Ce qu'il faut lire, et seulement ça, pour imprimer un reçu provisoire.
///
/// DAO **dédié** plutôt que trois lectures empruntées à Inscription, Classe et
/// Facturation : le ticket a ses propres besoins (identité d'école, matricule,
/// nom de classe, caissier stampé sur le paiement), et les disperser rendrait
/// impossible de vérifier d'un coup d'œil que le gabarit n'invente rien.
///
/// Toutes les lectures rendent `null` plutôt que de lever : un référentiel non
/// encore pullé est un cas NORMAL hors ligne, et le gabarit sait taire ce qu'il
/// ne connaît pas.
class ProvisionalTicketDao {
  final DatabaseExecutor _db;

  const ProvisionalTicketDao(this._db);

  /// Ce que le versement a encaissé, **par devise**, dérivé de ses imputations.
  ///
  /// Le versement portait un montant scalaire ; ce n'en était pas une propriété
  /// mais le résumé de ses allocations. Sur un ticket, la distinction compte :
  /// c'est la pièce que le payeur emporte.
  Future<MoneyBag> _amountsOf(String paymentId) async {
    final rows = await _db.rawQuery(
      'SELECT currency, SUM(amount_in_cents) AS total '
      'FROM payment_allocations WHERE payment_id = ? '
      'GROUP BY currency ORDER BY currency',
      [paymentId],
    );
    return MoneyBag.of([
      for (final r in rows)
        Money.parse(
          (r['total'] as int?) ?? 0,
          (r['currency'] as String?) ?? '',
        ),
    ]);
  }

  /// Le paiement, avec le caissier et l'appareil stampés à l'encaissement.
  Future<TicketPaymentRow?> findPayment(String paymentId) async {
    final rows = await _db.query(
      'payments',
      columns: const [
        'id',
        'student_id',
        'academic_year_id',
        'paid_at',
        'cashier_first_name',
        'cashier_last_name',
        'device_id',
        'sync_status',
      ],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return TicketPaymentRow(
      id: r['id'] as String,
      studentId: r['student_id'] as String,
      academicYearId: r['academic_year_id'] as String?,
      amounts: await _amountsOf(paymentId),
      paidAt: (r['paid_at'] as String?) ?? '',
      cashierFirstName: r['cashier_first_name'] as String?,
      cashierLastName: r['cashier_last_name'] as String?,
      deviceId: r['device_id'] as String?,
      syncStatus: (r['sync_status'] as String?) ?? 'PENDING_SYNC',
    );
  }

  /// Répartition ligne à ligne, dans l'ordre d'écriture — c'est une **saisie**
  /// du guichet (A-2), pas un calcul : elle s'imprime telle quelle.
  ///
  /// Le libellé est celui **gelé à l'encaissement** ; le code de la tranche est
  /// joint depuis la grille (v39). Sans lui, deux versements sur deux tranches
  /// d'un même minerval sortaient du même papier, mot pour mot.
  ///
  /// ⚠️ **`LEFT JOIN`, jamais `JOIN`** : le tarif peut avoir quitté l'appareil,
  /// et perdre une ligne de répartition sur un ticket, c'est remettre à une
  /// famille un papier dont le détail ne fait plus la somme.
  ///
  /// ⚠️ La composition « libellé (code) » est écrite ici, et pas via la clé
  /// `chargeDesignationWithTariffCode` des écrans : ce DAO n'a pas d'`l10n` — le
  /// ticket est **pur** par construction (« l'appelant traduit, le gabarit
  /// arrange »), et ses libellés lui arrivent déjà traduits. Ce qui compte est
  /// partagé : la règle qui décide si un code distingue quelque chose vient de
  /// [meaningfulTariffCode], la même que les six écrans.
  Future<List<TicketAllocationRow>> findAllocations(String paymentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.student_charge_label,
             pa.fee_code,
             pa.amount_in_cents,
             pa.currency,
             t.code AS t_fee_tariff_code
      FROM payment_allocations pa
      LEFT JOIN ref_fee_tariffs t ON t.id = pa.fee_tariff_id
      WHERE pa.payment_id = ?
      ''',
      [paymentId],
    );

    return rows
        .map((r) {
          final feeCode = (r['fee_code'] as String?) ?? '';
          final frozen = (r['student_charge_label'] as String?)?.trim() ?? '';
          // Un frais sans libellé retombe sur sa nature BRUTE (jamais traduite ici),
          // comportement d'origine : le ticket préfère un code lisible à un blanc.
          final base = frozen.isNotEmpty ? frozen : feeCode;
          final code = meaningfulTariffCode(
            code: r['t_fee_tariff_code'] as String?,
            feeCode: feeCode,
          );

          return TicketAllocationRow(
            label: code == null ? base : '$base ($code)',
            amountInCents: (r['amount_in_cents'] as int?) ?? 0,
            currency: (r['currency'] as String?) ?? '',
          );
        })
        .toList(growable: false);
  }

  /// Retient qu'un papier est SORTI pour ce versement.
  ///
  /// Écrit **uniquement** après une impression thermique réussie : c'est le seul
  /// signal qui prouve qu'un ticket existe physiquement. Le repli PDF, lui, rend
  /// la main dès que le spouleur a accepté le document — le caissier peut encore
  /// annuler la boîte système ou choisir « Enregistrer en PDF », et marquer sur
  /// ce signal-là déclarerait imprimé un ticket qui n'a jamais été tiré.
  ///
  /// Purement local : jamais poussé, jamais descendu. « Ce poste a servi le
  /// papier » est un fait d'appareil.
  Future<void> markTicketPrinted(String paymentId, DateTime at) async {
    await _db.update(
      'payments',
      {'ticket_printed_at': at.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  /// Vrai si un ticket est déjà sorti de CE poste pour ce versement.
  ///
  /// Rend `false` quand la ligne est introuvable : mieux vaut offrir un
  /// rattrapage inutile que refuser le seul chemin vers un papier qui manque.
  Future<bool> hasPrintedTicket(String paymentId) async {
    final rows = await _db.query(
      'payments',
      columns: const ['ticket_printed_at'],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['ticket_printed_at'] != null;
  }

  /// Numéro provisoire du reçu. On lit `provisional_number` **puis** `number` :
  /// la première colonne survit au scellement, la seconde est écrasée par le
  /// numéro définitif.
  Future<String?> findProvisionalNumber(String paymentId) async {
    final rows = await _db.query(
      'generated_documents',
      columns: const ['provisional_number', 'number'],
      where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
      whereArgs: [paymentId, 'PAYMENT', 'RC'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final provisional = (rows.first['provisional_number'] as String?)?.trim();
    if (provisional != null && provisional.isNotEmpty) return provisional;
    return (rows.first['number'] as String?)?.trim();
  }

  /// Identité de l'élève. `matriculation_number` est NULL hors ligne par
  /// construction — il est attribué à l'ACK.
  Future<TicketStudentRow?> findStudent(String studentId) async {
    final rows = await _db.query(
      'students',
      columns: const [
        'first_name',
        'last_name',
        'surname',
        'matriculation_number',
      ],
      where: 'id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return TicketStudentRow(
      firstName: (r['first_name'] as String?) ?? '',
      lastName: (r['last_name'] as String?) ?? '',
      surname: r['surname'] as String?,
      matriculationNumber: r['matriculation_number'] as String?,
    );
  }

  /// Dénomination et commune de l'établissement (zone Z1). `null` tant que le
  /// référentiel n'a pas été pullé.
  Future<TicketSchoolRow?> findSchool() async {
    final rows = await _db.query(
      'ref_school',
      columns: const ['name', 'municipality', 'city'],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return TicketSchoolRow(
      name: (r['name'] as String?) ?? '',
      municipality: r['municipality'] as String?,
      city: r['city'] as String?,
    );
  }

  /// Nom de la classe de l'élève sur l'année. `null` si le roster n'a pas été
  /// pullé — cas courant sur une tablette fraîche.
  ///
  /// La classe est **composée**, jamais lue brute dans le miroir : un transfert
  /// saisi hors ligne n'a pas encore repositionné `ref_classroom_members`, mais
  /// il fait déjà autorité partout ailleurs (roster, fiche élève, recherche).
  /// Sans cette composition, le ticket imprimerait l'ancienne classe pendant que
  /// tous les écrans affichent la nouvelle — deux vérités contradictoires sur la
  /// même tablette, dont l'une est remise sur papier.
  ///
  /// Même expression que `ClassroomLocalDataSource`, à dessein : c'est elle qui
  /// définit « la classe d'un élève » dans cette application.
  Future<String?> findClassroomName({
    required String studentId,
    String? academicYearId,
  }) async {
    final where = StringBuffer("m.student_id = ? AND m.status = 'ACTIVE'");
    final args = <Object?>[studentId];
    if (academicYearId != null && academicYearId.isNotEmpty) {
      where.write(' AND m.academic_year_id = ?');
      args.add(academicYearId);
    }

    final rows = await _db.rawQuery('''
      SELECT c.name AS name
      FROM ref_classroom_members m
      JOIN ref_classrooms c ON c.id = COALESCE(
        (SELECT t.to_classroom_id FROM classroom_transfers t
           WHERE t.student_id = m.student_id
             AND t.academic_year_id = m.academic_year_id
             AND t.sync_status <> 'SYNCED'
           ORDER BY t.transferred_at DESC LIMIT 1),
        m.classroom_id
      )
      WHERE $where
      ORDER BY m.updated_at DESC
      LIMIT 1
    ''', args);

    if (rows.isEmpty) return null;
    return (rows.first['name'] as String?)?.trim();
  }
}

class TicketPaymentRow {
  final String id;
  final String studentId;
  final String? academicYearId;

  /// Ce qui a été reçu, **par devise** — dérivé des imputations, comme partout
  /// ailleurs depuis que le versement n'a plus de montant à lui.
  final MoneyBag amounts;
  final String paidAt;
  final String? cashierFirstName;
  final String? cashierLastName;
  final String? deviceId;
  final String syncStatus;

  const TicketPaymentRow({
    required this.id,
    required this.studentId,
    this.academicYearId,
    required this.amounts,
    required this.paidAt,
    this.cashierFirstName,
    this.cashierLastName,
    this.deviceId,
    required this.syncStatus,
  });

  /// Nom affichable du caissier, `null` si aucune identité n'a été stampée
  /// (encaissement antérieur à la v19, ou annuaire muet au moment du geste).
  String? get cashierFullName {
    final parts = [
      cashierFirstName?.trim(),
      cashierLastName?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }
}

class TicketAllocationRow {
  final String label;
  final int amountInCents;

  /// La devise de CETTE imputation — elle solde une créance, donc une seule.
  final String currency;

  const TicketAllocationRow({
    required this.label,
    required this.amountInCents,
    required this.currency,
  });
}

class TicketStudentRow {
  final String firstName;
  final String lastName;
  final String? surname;
  final String? matriculationNumber;

  const TicketStudentRow({
    required this.firstName,
    required this.lastName,
    this.surname,
    this.matriculationNumber,
  });

  /// `NOM Post-nom Prénom` (zone Z2), dans l'ordre d'usage en RDC.
  String get fullName => [
    lastName.trim(),
    surname?.trim() ?? '',
    firstName.trim(),
  ].where((p) => p.isNotEmpty).join(' ');
}

class TicketSchoolRow {
  final String name;
  final String? municipality;
  final String? city;

  const TicketSchoolRow({required this.name, this.municipality, this.city});

  /// Ligne 2 de la zone Z1 : commune si connue, ville à défaut.
  String? get locality {
    final commune = municipality?.trim();
    if (commune != null && commune.isNotEmpty) return commune;
    final town = city?.trim();
    return (town != null && town.isNotEmpty) ? town : null;
  }
}
