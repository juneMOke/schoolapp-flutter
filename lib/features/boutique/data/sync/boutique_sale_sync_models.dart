/// Contrat de push d'une vente boutique — miroir de `openApi.yaml`
/// (`POST /api/v1/sync/boutique/sales`).
///
/// **Tout est en cents.** Un `double` qui traverserait cette couche finirait par
/// arrondir de l'argent, et le serveur vérifie l'arithmétique au centime :
/// `lineTotalInCents == unitPriceInCents × quantity`, et
/// `amounts` == Σ `lineTotalInCents` **devise par devise**. Un écart rend
/// `INCONSISTENT_TOTAL` — sur une vente déjà encaissée.
library;

import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';

/// La vente elle-même.
class BoutiqueSaleInput {
  /// uuid **client**, honoré par le serveur : la clé d'idempotence money-grade.
  /// Un rejeu après coupure ne compte jamais l'argent deux fois.
  final String id;

  /// Doit être une année **de cette école** : le serveur rend
  /// `UNKNOWN_ACADEMIC_YEAR` sinon — une année étrangère créerait une séquence
  /// éditique fantôme et rendrait la vente invisible au pull.
  final String academicYearId;

  /// **Facultatif comme les deux autres** (V114 serveur). Le triplet entier
  /// peut être omis : la vente est alors ANONYME, et son reçu n'imprime aucun
  /// bloc payeur plutôt qu'un nom que personne n'a donné. Une vente au comptant
  /// remet sa contrepartie sur-le-champ — aucune dette à rattacher, personne à
  /// recontacter — et exiger un nom pour encaisser un cahier faisait taper
  /// « X » au guichet : un champ rempli qui ne désigne personne.
  final String? payerLastName;

  final String? payerFirstName;
  final String? payerMiddleName;

  /// Optionnel et sans contrainte de format : le serveur normalise au mieux et
  /// n'échoue jamais dessus.
  final String? payerPhoneNumber;

  /// Ce qui a été encaissé comptant, **une entrée par devise**.
  ///
  /// Un même panier règle 450,00 $ d'uniformes et 90 000 FC de manuels : c'est
  /// un acte de caisse, donc une vente et un reçu — pas deux. Le serveur
  /// contrôle que ces montants sont bien la somme des lignes **devise par
  /// devise** (422 `INCONSISTENT_TOTAL`). Ne jamais additionner deux entrées.
  ///
  /// Une devise dont les lignes totalisent zéro — un article offert — n'a pas à
  /// y figurer.
  final MoneyBag amounts;

  /// Ce qui est réellement **entré dans le tiroir**, une entrée par devise
  /// reçue.
  ///
  /// **Facultatif au contrat** : absent, le serveur écrit l'identité — perçu =
  /// vendu, taux 1 — depuis les lignes. Un poste d'un build antérieur continue
  /// donc de vendre, et sa vente n'est jamais refusée pour ce champ.
  ///
  /// On l'envoie quand même, toujours : le repli serveur annoncerait des dollars
  /// sur une journée où le tiroir n'a vu que des francs.
  final List<TenderDraft> tenders;

  /// Heure **métier** de la vente, potentiellement bien antérieure au push.
  /// Clampée sur l'horloge serveur, et jamais un curseur de synchro.
  final String soldAt;

  const BoutiqueSaleInput({
    required this.id,
    required this.academicYearId,
    this.payerLastName,
    this.payerFirstName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.amounts,
    this.tenders = const [],
    required this.soldAt,
  });

  /// ⚠️ **Aucun `payerName` sur le fil** : le nom composé est *dérivé serveur*
  /// depuis ce triplet. En envoyer un le ferait ignorer, et laisserait croire
  /// que le client décide de ce qui s'imprime.
  Map<String, dynamic> toJson() => {
    'id': id,
    'academicYearId': academicYearId,
    if (payerLastName != null && payerLastName!.isNotEmpty)
      'payerLastName': payerLastName,
    if (payerFirstName != null && payerFirstName!.isNotEmpty)
      'payerFirstName': payerFirstName,
    if (payerMiddleName != null && payerMiddleName!.isNotEmpty)
      'payerMiddleName': payerMiddleName,
    if (payerPhoneNumber != null && payerPhoneNumber!.isNotEmpty)
      'payerPhoneNumber': payerPhoneNumber,
    'amounts': [
      for (final amount in amounts.entries)
        {'amountInCents': amount.amountInCents, 'currency': amount.currency},
    ],
    // Une liste vide sur le fil dirait « rien n'est entré » sur une vente
    // encaissée : la clé s'omet plutôt.
    //
    // ⚠️ **Se taire n'est plus neutre** depuis le contrat du 2026-09-04. Le
    // serveur écrit toujours l'identité pour un acte muet, mais il la marque
    // désormais `DERIVED` — un postulat, et non un constat de comptoir — et
    // chaque acte silencieux produit une ligne d'arbitrage
    // `TENDER_UNDECLARED` dans les écoles qui publient un taux de guichet.
    // `tendersFor` compose donc au moins l'identité pour toute vente non
    // vide : ce garde-fou ne couvre plus qu'un panier sans aucune ligne.
    if (tenders.isNotEmpty)
      'tenders': [
        for (final tender in tenders)
          {
            'amountInCents': tender.amountInCents,
            'currency': tender.currency,
            // Le taux en décimal, comme le `numeric(18,6)` du serveur : les
            // micro-unités sont une convention LOCALE, elles ne voyagent pas.
            'rate': tender.rateMicros / ExchangeRate.scale,
            'pivotCurrency': tender.pivotCurrency,
          },
      ],
    'soldAt': soldAt,
  };

  factory BoutiqueSaleInput.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleInput(
        id: j['id'] as String,
        academicYearId: j['academicYearId'] as String,
        payerLastName: j['payerLastName'] as String?,
        payerFirstName: j['payerFirstName'] as String?,
        payerMiddleName: j['payerMiddleName'] as String?,
        payerPhoneNumber: j['payerPhoneNumber'] as String?,
        amounts: _amountsOf(j),
        tenders: _tendersOf(j),
        soldAt: j['soldAt'] as String,
      );

  /// Relit les lignes d'encaissement, **sans jamais échouer**.
  ///
  /// Une tablette mise à jour hors ligne porte en file des ventes écrites par la
  /// version précédente, qui n'en avaient aucune. Les refuser les ferait
  /// basculer en `failed` — issue terminale de l'outbox : l'argent encaissé,
  /// reçu déjà remis, ne remonterait jamais. Absentes, le serveur écrit
  /// l'identité, et c'est exactement ce que valait cette vente-là.
  static List<TenderDraft> _tendersOf(Map<String, dynamic> j) {
    final raw = j['tenders'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          TenderDraft(
            amountInCents: (entry['amountInCents'] as num?)?.toInt() ?? 0,
            currency: (entry['currency'] as String?) ?? '',
            rateMicros:
                (((entry['rate'] as num?)?.toDouble() ?? 1) *
                        ExchangeRate.scale)
                    .round(),
            pivotCurrency:
                (entry['pivotCurrency'] as String?) ??
                (entry['currency'] as String?) ??
                '',
          ),
    ];
  }

  /// Relit les montants **quelle que soit la forme** du payload.
  ///
  /// Une tablette mise à jour hors ligne porte encore en file des ventes
  /// écrites par la version précédente, avec un `totalInCents` scalaire. Les
  /// refuser les ferait basculer en `failed` — issue terminale de l'outbox :
  /// l'argent encaissé, reçu déjà remis, ne remonterait jamais.
  static MoneyBag _amountsOf(Map<String, dynamic> j) {
    final raw = j['amounts'];
    if (raw is List) {
      return MoneyBag.of([
        for (final entry in raw)
          if (entry is Map<String, dynamic>)
            Money.parse(
              (entry['amountInCents'] as num?)?.toInt() ?? 0,
              (entry['currency'] as String?) ?? '',
            ),
      ]);
    }
    final cents = (j['totalInCents'] as num?)?.toInt();
    if (cents == null) return MoneyBag.empty;
    return MoneyBag.from(Money.parse(cents, (j['currency'] as String?) ?? ''));
  }
}

/// Une ligne du panier.
class BoutiqueSaleLineInput {
  final String articleId;

  /// L'enfant, ou `null` en walk-in.
  final String? beneficiaryStudentId;

  /// Le niveau choisi au guichet. **Ignoré** par le serveur dès qu'un
  /// bénéficiaire est nommé : c'est alors l'inscription qui fait foi. On
  /// l'envoie quand même quand il existe — il reste la meilleure trace de ce
  /// qui s'est passé au guichet si la dérivation échoue.
  final String? schoolLevelId;

  /// Attribut de remise, **sans effet sur le montant** (invariant I-3).
  final String? size;

  final int quantity;

  /// Le prix **appliqué** — une revendication, pas une autorité. Le serveur
  /// l'honore (l'argent est dans le tiroir) et compare au sien pour signaler
  /// tout écart.
  final int unitPriceInCents;

  final int lineTotalInCents;

  /// La devise de CETTE ligne — c'est l'article qui est tarifé dans une unité,
  /// donc un panier peut en mêler deux.
  ///
  /// **Envoyée par le poste et enregistrée telle quelle**, jamais déduite du
  /// catalogue : la caisse vend hors ligne sur une copie qui peut précéder un
  /// changement de devise, et déduire imprimerait des dollars sur un reçu dont
  /// le tiroir contient des francs.
  ///
  /// Un écart de catalogue **ne refuse pas la vente** — l'argent est là, dans
  /// l'unité encaissée, et aucun rafraîchissement ne l'y changerait : l'écart
  /// part en anomalie. Seul un code hors de la liste close est refusé
  /// (422 `UNKNOWN_CURRENCY`), et celui-là est un bug client.
  final String currency;

  const BoutiqueSaleLineInput({
    required this.articleId,
    this.beneficiaryStudentId,
    this.schoolLevelId,
    this.size,
    required this.quantity,
    required this.unitPriceInCents,
    required this.lineTotalInCents,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'beneficiaryStudentId': beneficiaryStudentId,
    'schoolLevelId': schoolLevelId,
    'size': size,
    'quantity': quantity,
    'unitPriceInCents': unitPriceInCents,
    'lineTotalInCents': lineTotalInCents,
    'currency': currency,
  };

  factory BoutiqueSaleLineInput.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleLineInput(
        articleId: j['articleId'] as String,
        beneficiaryStudentId: j['beneficiaryStudentId'] as String?,
        schoolLevelId: j['schoolLevelId'] as String?,
        size: j['size'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        unitPriceInCents: (j['unitPriceInCents'] as num).toInt(),
        // Repli vide plutôt qu'une devise inventée : une ligne figée par une
        // version antérieure n'en portait pas, et écrire « USD » à sa place
        // ferait imprimer des dollars sur un reçu qui n'en est pas.
        currency: (j['currency'] as String?) ?? '',
        lineTotalInCents: (j['lineTotalInCents'] as num).toInt(),
      );
}

/// L'agrégat poussé : la vente et son panier, en **un seul appel** — une seule
/// maille d'outbox, une seule transaction serveur.
class BoutiqueSaleRequest {
  final BoutiqueSaleInput sale;
  final List<BoutiqueSaleLineInput> lines;

  /// Auteur de la saisie (uuid serveur). Doit être **celui qui pousse**, sinon
  /// 403 : on ne pousse que son propre outbox.
  final String authorId;

  const BoutiqueSaleRequest({
    required this.sale,
    required this.lines,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'sale': sale.toJson(),
    'lines': [for (final line in lines) line.toJson()],
    'authorId': authorId,
  };

  factory BoutiqueSaleRequest.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleRequest(
        sale: BoutiqueSaleInput.fromJson(j['sale'] as Map<String, dynamic>),
        lines: [
          for (final line in (j['lines'] as List<dynamic>? ?? const []))
            BoutiqueSaleLineInput.fromJson(line as Map<String, dynamic>),
        ],
        authorId: j['authorId'] as String,
      );
}

/// Le reçu scellé rendu par l'ACK.
class SealedSaleDocument {
  final String? type;
  final String? documentNumber;
  final String? status;

  const SealedSaleDocument({this.type, this.documentNumber, this.status});

  factory SealedSaleDocument.fromJson(Map<String, dynamic> j) =>
      SealedSaleDocument(
        type: j['type'] as String?,
        documentNumber: j['documentNumber'] as String?,
        status: j['status'] as String?,
      );
}

/// Un écart entre le prix encaissé et celui du catalogue serveur.
///
/// **Informatif, jamais bloquant** : l'argent a été reçu, et refuser la vente
/// laisserait du cash absent des livres. Quand ce signal apparaît, il ne dit pas
/// « le caissier s'est trompé », il dit **la garantie de fraîcheur du catalogue
/// a lâché**.
class PriceDivergenceSignal {
  final String? lineId;
  final String? articleId;
  final String? articleCode;
  final int? appliedPriceInCents;
  final int? catalogPriceInCents;

  const PriceDivergenceSignal({
    this.lineId,
    this.articleId,
    this.articleCode,
    this.appliedPriceInCents,
    this.catalogPriceInCents,
  });

  factory PriceDivergenceSignal.fromJson(Map<String, dynamic> j) =>
      PriceDivergenceSignal(
        lineId: j['lineId'] as String?,
        articleId: j['articleId'] as String?,
        articleCode: j['articleCode'] as String?,
        appliedPriceInCents: (j['appliedPriceInCents'] as num?)?.toInt(),
        catalogPriceInCents: (j['catalogPriceInCents'] as num?)?.toInt(),
      );
}

/// ACK canonique d'une vente — le canal unique de réconciliation.
///
/// **Aucune créance, aucun solde, aucun reste**, à la différence de l'ACK
/// d'encaissement de frais : une vente boutique est comptant intégral, et en
/// renvoyer un champ vide laisserait croire le contraire.
class BoutiqueSaleResponse {
  final String? saleId;

  /// Identifiant d'archive du reçu.
  ///
  /// ⚠️ **Ne pas s'y fier seul** pour décider qu'un reçu est scellé : lire
  /// [documents] d'abord. Le champ a longtemps été nul sur tout 201 — un défaut
  /// serveur corrigé depuis, mais le contrat autorise toujours l'absence.
  final String? receiptDocumentId;

  final int? totalInCents;
  final String? currency;

  /// Possiblement **vide** : le scellement est best-effort et hors transaction.
  /// Un échec d'imprimerie laisse la vente enregistrée — la caisse garde son
  /// ticket provisoire et réclame le scellé plus tard.
  final List<SealedSaleDocument> documents;

  final List<PriceDivergenceSignal> divergences;

  const BoutiqueSaleResponse({
    this.saleId,
    this.receiptDocumentId,
    this.totalInCents,
    this.currency,
    this.documents = const [],
    this.divergences = const [],
  });

  /// Vrai si le serveur annonce un reçu scellé.
  ///
  /// `documents` fait foi ; `receiptDocumentId` ne sert qu'à le retrouver.
  bool get hasSealedReceipt => documents.isNotEmpty;

  /// Le numéro du reçu, quand il existe.
  String? get receiptNumber =>
      documents.isEmpty ? null : documents.first.documentNumber;

  /// Parsing **tolérant** : un ACK dont la forme surprend ne doit pas faire
  /// échouer un encaissement déjà acquitté côté serveur.
  factory BoutiqueSaleResponse.fromJson(Map<String, dynamic> j) {
    final sale = j['sale'];
    final saleMap = sale is Map<String, dynamic> ? sale : const {};
    return BoutiqueSaleResponse(
      saleId: saleMap['id'] as String?,
      receiptDocumentId: saleMap['receiptDocumentId'] as String?,
      totalInCents: (saleMap['totalInCents'] as num?)?.toInt(),
      currency: saleMap['currency'] as String?,
      documents: [
        for (final doc in (j['documents'] as List<dynamic>? ?? const []))
          if (doc is Map<String, dynamic>) SealedSaleDocument.fromJson(doc),
      ],
      divergences: [
        for (final signal in (j['divergences'] as List<dynamic>? ?? const []))
          if (signal is Map<String, dynamic>)
            PriceDivergenceSignal.fromJson(signal),
      ],
    );
  }
}
