import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// L'école, telle que le ticket la nomme.
class TicketSchoolIdentity {
  final String name;
  final String? address;

  const TicketSchoolIdentity({required this.name, this.address});
}

/// Compose le ticket de vente à partir de ce que la caisse a écrit.
///
/// **100 % local, et c'est le point** : le ticket doit sortir alors que le
/// serveur ne sait encore rien. Tout ce dont il a besoin a été figé au moment de
/// la vente — libellés d'articles, nom du bénéficiaire, montants — précisément
/// pour qu'aucune lecture ne puisse échouer ici.
class SaleTicketComposer {
  final Database _db;

  const SaleTicketComposer(this._db);

  /// Le modèle du ticket, ou `null` si l'école reste introuvable **et** que
  /// la vente n'a rien à imprimer.
  ///
  /// Une école inconnue n'empêche PAS d'imprimer : le ticket vaut par son
  /// montant, son payeur et son caissier, pas par son en-tête.
  Future<SaleTicketModel> compose(
    RecordedSale recorded, {
    required SaleTicketLabels labels,
    required Map<String, String> levelLabels,
  }) async {
    final school = await _findSchool(recorded.sale.schoolId);
    final sale = recorded.sale;

    return SaleTicketModel(
      schoolName: school?.name ?? '',
      schoolAddress: school?.address,
      // Le numéro définitif dès qu'il existe, le provisoire sinon. Un ticket
      // sans aucune référence serait irrapprochable — d'où le repli sur
      // l'identifiant de la vente, qui en est toujours un.
      reference: sale.receiptNumber ?? ProvisionalSaleReference.of(sale.id),
      // `isProvisional` se lit sur l'absence de NUMÉRO, pas sur l'état réseau :
      // une vente poussée dont l'ACK n'a rendu aucun document reste provisoire
      // même en ligne, et c'est exactement ce que le porteur doit savoir.
      isProvisional: sale.receiptNumber == null,
      soldAt: DateTime.tryParse(sale.soldAt)?.toLocal() ?? DateTime.now(),
      cashierFullName: sale.collectedByName,
      payerFullName: sale.payerName ?? sale.payerLastName,
      payerPhoneNumber: sale.payerPhoneNumber,
      lines: [
        for (final line in recorded.lines)
          SaleTicketLine(
            label: line.articleLabel,
            quantity: line.quantity,
            unitPriceInCents: line.unitPriceInCents,
            lineTotalInCents: line.lineTotalInCents,
            // Le libellé du niveau est résolu par l'appelant, qui tient le
            // référentiel : le figer sur la ligne coûterait une colonne pour
            // une information que le catalogue porte déjà.
            levelLabel: line.schoolLevelId == null
                ? null
                : levelLabels[line.schoolLevelId],
            size: line.size,
            beneficiaryName: line.beneficiaryName,
          ),
      ],
      totalInCents: sale.totalInCents,
      currency: sale.currency,
      labels: labels,
    );
  }

  /// Une lecture d'en-tête ne fait jamais tomber un ticket : l'échec rend
  /// `null`, et l'école reste anonyme sur le papier.
  Future<TicketSchoolIdentity?> _findSchool(String schoolId) async {
    try {
      final rows = await _db.query(
        'ref_school',
        columns: const ['name', 'address', 'municipality', 'city'],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      return TicketSchoolIdentity(
        name: (row['name'] as String?) ?? '',
        address: [
          row['address'] as String?,
          row['municipality'] as String?,
          row['city'] as String?,
        ].where((part) => part != null && part.trim().isNotEmpty).join(' - '),
      );
    } catch (_) {
      return null;
    }
  }
}
