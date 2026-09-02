import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une vente telle qu'elle est stockée localement.
///
/// `id` est l'uuid **client** honoré par le serveur : il n'y a pas de
/// `client_uuid` séparé comme sur `payments`, parce qu'il n'y a rien à remapper.
class BoutiqueSaleLocalModel {
  final String id;
  final String schoolId;
  final String academicYearId;

  /// Les trois noms sont NULLABLES (v43) : une vente au comptant remet sa
  /// contrepartie sur-le-champ, et exiger un nom pour encaisser un cahier
  /// faisait taper « X » au guichet. `null` — jamais `''` — quand rien n'a été
  /// donné : c'est ce que le ticket et le reçu lisent pour escamoter le bloc
  /// payeur au lieu d'imprimer un cadre creux.
  final String? payerLastName;
  final String? payerMiddleName;
  final String? payerFirstName;
  final String? payerPhoneNumber;

  /// Nom composé — **dérivé serveur** sur le fil, mais recopié ici pour que le
  /// ticket imprimé au guichet dise la même chose que le reçu scellé, sans
  /// attendre la synchro.
  final String? payerName;

  final String? collectedById;
  final String? collectedByName;

  /// Heure **métier** de la vente (ISO-8601). C'est elle qui décide de quelle
  /// caisse la vente relève, pas sa date d'arrivée au serveur.
  final String soldAt;

  final String? receiptDocumentId;
  final String? receiptNumber;
  final String? deviceId;
  final String syncStatus;
  final int updatedAt;

  const BoutiqueSaleLocalModel({
    required this.id,
    required this.schoolId,
    required this.academicYearId,
    this.payerLastName,
    this.payerMiddleName,
    this.payerFirstName,
    this.payerPhoneNumber,
    this.payerName,
    this.collectedById,
    this.collectedByName,
    required this.soldAt,
    this.receiptDocumentId,
    this.receiptNumber,
    this.deviceId,
    this.syncStatus = 'PENDING_SYNC',
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'school_id': schoolId,
    'academic_year_id': academicYearId,
    'payer_last_name': payerLastName,
    'payer_middle_name': payerMiddleName,
    'payer_first_name': payerFirstName,
    'payer_phone_number': payerPhoneNumber,
    'payer_name': payerName,
    'collected_by_id': collectedById,
    'collected_by_name': collectedByName,
    'sold_at': soldAt,
    'receipt_document_id': receiptDocumentId,
    'receipt_number': receiptNumber,
    'device_id': deviceId,
    'sync_status': syncStatus,
    'updated_at': updatedAt,
  };

  factory BoutiqueSaleLocalModel.fromMap(Map<String, Object?> map) =>
      BoutiqueSaleLocalModel(
        id: map['id'] as String,
        schoolId: map['school_id'] as String,
        academicYearId: map['academic_year_id'] as String,
        payerLastName: map['payer_last_name'] as String?,
        payerMiddleName: map['payer_middle_name'] as String?,
        payerFirstName: map['payer_first_name'] as String?,
        payerPhoneNumber: map['payer_phone_number'] as String?,
        payerName: map['payer_name'] as String?,
        collectedById: map['collected_by_id'] as String?,
        collectedByName: map['collected_by_name'] as String?,
        soldAt: map['sold_at'] as String,
        receiptDocumentId: map['receipt_document_id'] as String?,
        receiptNumber: map['receipt_number'] as String?,
        deviceId: map['device_id'] as String?,
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      );
}

/// Une ligne du panier, figée à la vente.
class BoutiqueSaleLineLocalModel {
  final String id;
  final String saleId;
  final String articleId;

  /// **Recopié**, jamais joint : le catalogue est remplacé en bloc à chaque
  /// bundle, et une vente d'hier doit rester lisible après le retrait de son
  /// article.
  final String articleLabel;

  final String? articleCode;
  final String? beneficiaryStudentId;
  final String? beneficiaryName;
  final String? schoolLevelId;
  final String? size;
  final int quantity;
  final int unitPriceInCents;
  final int lineTotalInCents;

  /// La devise de cette ligne — celle de l'article tel qu'il a été vendu.
  final String currency;

  /// Ce que le catalogue serveur disait — `null` quand il ne disait plus rien.
  /// **Jamais zéro**, qui se relirait « il disait gratuit ».
  final int? catalogPriceInCents;

  final int position;

  const BoutiqueSaleLineLocalModel({
    required this.id,
    required this.saleId,
    required this.articleId,
    required this.articleLabel,
    this.articleCode,
    this.beneficiaryStudentId,
    this.beneficiaryName,
    this.schoolLevelId,
    this.size,
    required this.quantity,
    required this.unitPriceInCents,
    required this.lineTotalInCents,
    required this.currency,
    this.catalogPriceInCents,
    this.position = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'sale_id': saleId,
    'article_id': articleId,
    'article_label': articleLabel,
    'article_code': articleCode,
    'beneficiary_student_id': beneficiaryStudentId,
    'beneficiary_name': beneficiaryName,
    'school_level_id': schoolLevelId,
    'size': size,
    'quantity': quantity,
    'unit_price_in_cents': unitPriceInCents,
    'line_total_in_cents': lineTotalInCents,
    'currency': currency,
    'catalog_price_in_cents': catalogPriceInCents,
    'position': position,
  };

  factory BoutiqueSaleLineLocalModel.fromMap(Map<String, Object?> map) =>
      BoutiqueSaleLineLocalModel(
        id: map['id'] as String,
        saleId: map['sale_id'] as String,
        articleId: map['article_id'] as String,
        articleLabel: map['article_label'] as String,
        articleCode: map['article_code'] as String?,
        beneficiaryStudentId: map['beneficiary_student_id'] as String?,
        beneficiaryName: map['beneficiary_name'] as String?,
        schoolLevelId: map['school_level_id'] as String?,
        size: map['size'] as String?,
        quantity: (map['quantity'] as num).toInt(),
        unitPriceInCents: (map['unit_price_in_cents'] as num).toInt(),
        lineTotalInCents: (map['line_total_in_cents'] as num).toInt(),
        currency: (map['currency'] as String?) ?? '',
        catalogPriceInCents: (map['catalog_price_in_cents'] as num?)?.toInt(),
        position: (map['position'] as num?)?.toInt() ?? 0,
      );
}

/// Les montants d'une vente, **dérivés de ses lignes**.
///
/// La vente portait un `total_in_cents` + `currency` scalaires ; ce n'étaient
/// pas des propriétés de la vente mais le résumé de ses lignes, juste tant
/// qu'un panier ne réglait qu'une unité. Un panier qui règle 450,00 $
/// d'uniformes et 90 000 FC de manuels n'a pas de total unique.
extension BoutiqueSaleLineTotals on Iterable<BoutiqueSaleLineLocalModel> {
  MoneyBag get totals => MoneyBag.sumBy(
    this,
    (line) => Money.parse(line.lineTotalInCents, line.currency),
  );
}

/// Une ligne d'encaissement d'une vente — ce qui est **entré dans le tiroir**.
///
/// Sœur de [BoutiqueSaleLineLocalModel], à la même profondeur : le panier dit ce
/// qui a été vendu et dans quelle devise il est tarifé, celle-ci dit ce que le
/// client a réellement posé. Les deux se confondaient tant que l'unité était la
/// même ; depuis qu'un franc paie un cahier tarifé en dollars, les confondre
/// ferait annoncer des dollars sur une journée où le tiroir n'a vu que des
/// francs.
class BoutiqueSaleTenderLocalModel {
  final String id;
  final String saleId;

  /// Le **net conservé**, jamais le montant présenté : 120 000 tendus, 5 000
  /// rendus, on écrit 115 000.
  final int amountInCents;

  /// La devise réellement posée au comptoir.
  final String currency;

  /// Le taux de guichet **gelé**, en micro-unités. `1 000 000` = taux 1, le cas
  /// où perçu et vendu se confondent.
  final int rateMicros;

  /// La devise du **catalogue** que cette ligne règle.
  final String pivotCurrency;

  const BoutiqueSaleTenderLocalModel({
    required this.id,
    required this.saleId,
    required this.amountInCents,
    required this.currency,
    this.rateMicros = ExchangeRate.scale,
    required this.pivotCurrency,
  });

  factory BoutiqueSaleTenderLocalModel.fromMap(Map<String, Object?> map) =>
      BoutiqueSaleTenderLocalModel(
        id: (map['id'] as String?) ?? '',
        saleId: (map['sale_id'] as String?) ?? '',
        amountInCents: (map['amount_in_cents'] as num?)?.toInt() ?? 0,
        currency: (map['currency'] as String?) ?? '',
        rateMicros: (map['rate_micros'] as num?)?.toInt() ?? ExchangeRate.scale,
        pivotCurrency: (map['pivot_currency'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'sale_id': saleId,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'rate_micros': rateMicros,
    'pivot_currency': pivotCurrency,
  };

  /// La ligne telle que le contrat la pousse.
  TenderDraft toDraft() => TenderDraft(
    amountInCents: amountInCents,
    currency: currency,
    rateMicros: rateMicros,
    pivotCurrency: pivotCurrency,
  );
}
