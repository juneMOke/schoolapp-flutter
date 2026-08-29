/// Contrat de push d'une vente boutique — miroir de `openApi.yaml`
/// (`POST /api/v1/sync/boutique/sales`).
///
/// **Tout est en cents.** Un `double` qui traverserait cette couche finirait par
/// arrondir de l'argent, et le serveur vérifie l'arithmétique au centime :
/// `lineTotalInCents == unitPriceInCents × quantity`, et
/// `totalInCents == Σ lineTotalInCents`. Un écart rend `INCONSISTENT_TOTAL` —
/// sur une vente déjà encaissée.
library;

/// La vente elle-même.
class BoutiqueSaleInput {
  /// uuid **client**, honoré par le serveur : la clé d'idempotence money-grade.
  /// Un rejeu après coupure ne compte jamais l'argent deux fois.
  final String id;

  /// Doit être une année **de cette école** : le serveur rend
  /// `UNKNOWN_ACADEMIC_YEAR` sinon — une année étrangère créerait une séquence
  /// éditique fantôme et rendrait la vente invisible au pull.
  final String academicYearId;

  /// Le seul champ d'identité **exigé** par le serveur.
  final String payerLastName;

  final String? payerFirstName;
  final String? payerMiddleName;

  /// Optionnel et sans contrainte de format : le serveur normalise au mieux et
  /// n'échoue jamais dessus.
  final String? payerPhoneNumber;

  final int totalInCents;
  final String currency;

  /// Heure **métier** de la vente, potentiellement bien antérieure au push.
  /// Clampée sur l'horloge serveur, et jamais un curseur de synchro.
  final String soldAt;

  const BoutiqueSaleInput({
    required this.id,
    required this.academicYearId,
    required this.payerLastName,
    this.payerFirstName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.totalInCents,
    required this.currency,
    required this.soldAt,
  });

  /// ⚠️ **Aucun `payerName` sur le fil** : le nom composé est *dérivé serveur*
  /// depuis ce triplet. En envoyer un le ferait ignorer, et laisserait croire
  /// que le client décide de ce qui s'imprime.
  Map<String, dynamic> toJson() => {
    'id': id,
    'academicYearId': academicYearId,
    'payerLastName': payerLastName,
    if (payerFirstName != null && payerFirstName!.isNotEmpty)
      'payerFirstName': payerFirstName,
    if (payerMiddleName != null && payerMiddleName!.isNotEmpty)
      'payerMiddleName': payerMiddleName,
    if (payerPhoneNumber != null && payerPhoneNumber!.isNotEmpty)
      'payerPhoneNumber': payerPhoneNumber,
    'totalInCents': totalInCents,
    'currency': currency,
    'soldAt': soldAt,
  };

  factory BoutiqueSaleInput.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleInput(
        id: j['id'] as String,
        academicYearId: j['academicYearId'] as String,
        payerLastName: j['payerLastName'] as String,
        payerFirstName: j['payerFirstName'] as String?,
        payerMiddleName: j['payerMiddleName'] as String?,
        payerPhoneNumber: j['payerPhoneNumber'] as String?,
        totalInCents: (j['totalInCents'] as num).toInt(),
        currency: j['currency'] as String,
        soldAt: j['soldAt'] as String,
      );
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

  const BoutiqueSaleLineInput({
    required this.articleId,
    this.beneficiaryStudentId,
    this.schoolLevelId,
    this.size,
    required this.quantity,
    required this.unitPriceInCents,
    required this.lineTotalInCents,
  });

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'beneficiaryStudentId': beneficiaryStudentId,
    'schoolLevelId': schoolLevelId,
    'size': size,
    'quantity': quantity,
    'unitPriceInCents': unitPriceInCents,
    'lineTotalInCents': lineTotalInCents,
  };

  factory BoutiqueSaleLineInput.fromJson(Map<String, dynamic> j) =>
      BoutiqueSaleLineInput(
        articleId: j['articleId'] as String,
        beneficiaryStudentId: j['beneficiaryStudentId'] as String?,
        schoolLevelId: j['schoolLevelId'] as String?,
        size: j['size'] as String?,
        quantity: (j['quantity'] as num).toInt(),
        unitPriceInCents: (j['unitPriceInCents'] as num).toInt(),
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
