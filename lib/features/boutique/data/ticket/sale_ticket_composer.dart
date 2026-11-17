import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/domain/receipt_emission_day.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sections.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Compose le ticket de vente à partir de ce que la caisse a écrit.
///
/// **100 % local** : tout ce dont le ticket a besoin a été figé à la vente —
/// libellés d'articles, nom du bénéficiaire, montants, règlements — ou posé par
/// le serveur sur la vente (numéro, jour d'émission, QR). Aucune lecture réseau
/// ne peut donc échouer ici.
///
/// ⚠️ **Pas de numéro définitif, pas de ticket** : comme le ticket de
/// perception, le ticket de vente attend son `ETL-RV-…`. La vente reste
/// encaissée ; seul le papier attend la synchronisation.
class SaleTicketComposer {
  final Database _db;

  const SaleTicketComposer(this._db);

  Future<Either<Failure, SaleTicketModel>> compose(
    RecordedSale recorded, {
    required SaleTicketLabels labels,
    required Map<String, String> levelLabels,
  }) async {
    final sale = recorded.sale;
    final number = sale.receiptNumber?.trim() ?? '';
    if (number.isEmpty) return const Left(ReceiptAwaitingNumberFailure());

    try {
      final school = await _findSchool(sale.schoolId);
      final tenders = await _tendersOf(sale.id);
      return Right(
        SaleTicketModel(
          school: school ?? const TicketSchoolHeader(name: ''),
          receiptNumber: number,
          // L'heure de l'école, pas celle du poste : une tablette réglée en UTC
          // daterait du 29 une vente faite le 30 à 0 h 30 à Kinshasa.
          soldAt: SchoolTime.wallClock(
            DateTime.tryParse(sale.soldAt) ?? DateTime.now(),
          ),
          receiptIssuedOn: ReceiptEmissionDay.toDate(sale.receiptEmittedOn),
          verificationUrl: _trimmedOrNull(sale.receiptVerificationUrl),
          cashierFullName: sale.collectedByName,
          // `null` — jamais `''` — quand la vente est anonyme : c'est ce que le
          // gabarit lit pour escamoter le bloc payeur entier. Le nom composé du
          // serveur en priorité, le nom de famille saisi à défaut.
          payerFullName: _trimmedOrNull(sale.payerName ?? sale.payerLastName),
          payerPhoneNumber: sale.payerPhoneNumber,
          lines: [
            for (final line in recorded.lines)
              SaleTicketLine(
                label: line.articleLabel,
                quantity: line.quantity,
                unitPriceInCents: line.unitPriceInCents,
                lineTotalInCents: line.lineTotalInCents,
                currency: line.currency,
                // Le libellé du niveau est résolu par l'appelant, qui tient le
                // référentiel.
                levelLabel: line.schoolLevelId == null
                    ? null
                    : levelLabels[line.schoolLevelId],
                size: line.size,
                beneficiaryName: line.beneficiaryName,
              ),
          ],
          // Une vente d'avant les lignes d'encaissement n'en a aucune : le
          // tiroir a alors reçu exactement le panier, devise par devise.
          tenders: tenders.isEmpty
              ? TicketTenderLine.identityFrom(recorded.lines.totals)
              : tenders,
          labels: labels,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Ticket de vente illisible en local : $e'));
    }
  }

  /// L'école de la VENTE, sous le même en-tête que le ticket de perception.
  ///
  /// Une lecture d'en-tête ne fait jamais tomber un ticket : l'échec rend
  /// `null`, et l'école reste anonyme sur le papier — le ticket vaut par son
  /// numéro, son montant et son caissier.
  Future<TicketSchoolHeader?> _findSchool(String schoolId) async {
    try {
      final rows = await _db.query(
        'ref_school',
        columns: const [
          'name',
          'address',
          'municipality',
          'city',
          'email',
          'phone',
          'till_phone',
        ],
        where: 'id = ?',
        whereArgs: [schoolId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      return TicketSchoolRow(
        name: (row['name'] as String?) ?? '',
        address: row['address'] as String?,
        municipality: row['municipality'] as String?,
        city: row['city'] as String?,
        email: row['email'] as String?,
        phone: row['phone'] as String?,
        tillPhone: row['till_phone'] as String?,
      ).toHeader();
    } catch (_) {
      return null;
    }
  }

  /// Ce qui est entré dans le tiroir pour cette vente.
  Future<List<TicketTenderLine>> _tendersOf(String saleId) async {
    final rows = await _db.query(
      'boutique_sale_tenders',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'pivot_currency, currency, id',
    );
    return [
      for (final row in rows)
        _tenderLine(BoutiqueSaleTenderLocalModel.fromMap(row)),
    ];
  }

  static TicketTenderLine _tenderLine(BoutiqueSaleTenderLocalModel tender) =>
      TicketTenderLine(
        amountInCents: tender.amountInCents,
        currency: tender.currency,
        rateMicros: tender.rateMicros,
        pivotCurrency: tender.pivotCurrency,
      );

  /// Rend `null` plutôt qu'une chaîne vide ou blanche.
  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
