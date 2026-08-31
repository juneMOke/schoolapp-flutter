import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une vente telle qu'un delta de synchronisation la décrit.
///
/// **Ce que ce flux apporte et qu'aucun autre ne donne** : une caisse apprend
/// les ventes faites *ailleurs* — à l'autre guichet, ou par elle-même avant une
/// réinstallation. Sans lui, le total de caisse affiché sur un poste ne
/// compterait que ce que ce poste a lui-même vendu, et deux caissiers verraient
/// deux caisses différentes le même jour.
///
/// Les lignes descendent **avec** la vente, contrairement au delta des pièces
/// éditiques qui ne porte que des métadonnées : un panier pèse quelques
/// centaines d'octets, et rouvrir un ticket exige son détail.
class BoutiqueSaleDeltaDto {
  final String id;
  final String academicYearId;

  /// Nom composé, dérivé serveur.
  final String? payerName;

  /// Identité découpée — descendue depuis l'alignement du contrat. Absente sur
  /// une vente d'avant, où seul [payerName] existe.
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  final String? payerPhoneNumber;

  /// L'agent qui a encaissé, résolu à l'envoi — jamais l'adresse e-mail de
  /// connexion, qui n'a rien à faire sur un ticket.
  final String? collectedById;
  final String? collectedByName;

  /// Ce qui a été encaissé, **une entrée par devise**, dérivé des lignes.
  final MoneyBag amounts;
  final String soldAt;

  /// `null` **tant que le reçu n'est pas scellé** : le poste sait alors qu'il
  /// garde son ticket provisoire. C'est la seule voie différée par laquelle un
  /// scellement tardif redescend.
  final String? receiptDocumentId;

  final List<BoutiqueSaleLineDeltaDto> lines;
  final String serverUpdatedAt;

  const BoutiqueSaleDeltaDto({
    required this.id,
    required this.academicYearId,
    this.payerName,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.collectedById,
    this.collectedByName,
    required this.amounts,
    required this.soldAt,
    this.receiptDocumentId,
    this.lines = const [],
    required this.serverUpdatedAt,
  });

  factory BoutiqueSaleDeltaDto.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleDeltaDto(
        id: j['id'] as String,
        academicYearId: j['academicYearId'] as String,
        payerName: j['payerName'] as String?,
        payerFirstName: j['payerFirstName'] as String?,
        payerLastName: j['payerLastName'] as String?,
        payerMiddleName: j['payerMiddleName'] as String?,
        payerPhoneNumber: j['payerPhoneNumber'] as String?,
        collectedById: j['collectedById'] as String?,
        collectedByName: j['collectedByName'] as String?,
        amounts: MoneyBag.of([
          for (final raw in (j['amounts'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic>)
              Money.parse(
                (raw['amountInCents'] as num?)?.toInt() ?? 0,
                (raw['currency'] as String?) ?? '',
              ),
        ]),
        soldAt: j['soldAt'] as String,
        receiptDocumentId: j['receiptDocumentId'] as String?,
        lines: [
          for (final line in (j['lines'] as List<dynamic>? ?? const []))
            if (line is Map<String, dynamic>)
              BoutiqueSaleLineDeltaDto.fromJson(line),
        ],
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );
}

/// Une ligne du panier, telle qu'elle redescend.
class BoutiqueSaleLineDeltaDto {
  final String id;
  final String articleId;
  final String? articleLabel;
  final String? beneficiaryStudentId;
  final String? schoolLevelId;
  final String? size;
  final int quantity;
  final int unitPriceInCents;
  final int lineTotalInCents;

  /// La devise de CETTE ligne, telle que la caisse l'a encaissée.
  final String currency;

  const BoutiqueSaleLineDeltaDto({
    required this.id,
    required this.articleId,
    this.articleLabel,
    this.beneficiaryStudentId,
    this.schoolLevelId,
    this.size,
    required this.quantity,
    required this.unitPriceInCents,
    required this.lineTotalInCents,
    required this.currency,
  });

  factory BoutiqueSaleLineDeltaDto.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleLineDeltaDto(
        id: j['id'] as String,
        articleId: j['articleId'] as String,
        articleLabel: j['articleLabel'] as String?,
        beneficiaryStudentId: j['beneficiaryStudentId'] as String?,
        schoolLevelId: j['schoolLevelId'] as String?,
        size: j['size'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        unitPriceInCents: (j['unitPriceInCents'] as num).toInt(),
        lineTotalInCents: (j['lineTotalInCents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? '',
      );
}

/// Page keyset de ventes.
class BoutiqueSalePageDto implements KeysetPageDto<BoutiqueSaleDeltaDto> {
  @override
  final List<BoutiqueSaleDeltaDto> items;

  @override
  final KeysetPageEnvelope page;

  const BoutiqueSalePageDto({required this.items, required this.page});

  factory BoutiqueSalePageDto.fromJson(Map<String, dynamic> j) =>
      BoutiqueSalePageDto(
        items: [
          for (final item in (j['items'] as List<dynamic>? ?? const []))
            if (item is Map<String, dynamic>)
              BoutiqueSaleDeltaDto.fromJson(item),
        ],
        page: KeysetPageEnvelope.fromJson(j),
      );
}
