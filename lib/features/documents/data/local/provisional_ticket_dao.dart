import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

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

  /// Ce qui est **entré dans le tiroir** pour ce versement, ligne par ligne.
  ///
  /// Lu depuis `payment_tenders`, jamais dérivé des imputations : le champ
  /// « montant reçu » du ticket portait de l'imputé, et le jour où un franc
  /// règle un dollar il annoncerait des dollars à un parent qui a posé des
  /// francs. Le backfill de la v41 garantit qu'aucun versement n'est sans
  /// ligne — il n'y a donc **pas** de repli sur les allocations, qui ferait la
  /// seconde voie de lecture qu'on s'interdit.
  ///
  /// Regroupé par (devise reçue, pivot, taux) : deux lignes d'une même pile de
  /// billets s'impriment comme une seule, ce qu'elles étaient sur le comptoir.
  Future<List<TicketTenderRow>> findTenders(String paymentId) async {
    final rows = await _db.rawQuery(
      'SELECT currency, pivot_currency, rate_micros, '
      'SUM(amount_in_cents) AS total '
      'FROM payment_tenders WHERE payment_id = ? '
      'GROUP BY currency, pivot_currency, rate_micros '
      'ORDER BY currency, pivot_currency',
      [paymentId],
    );
    return [
      for (final r in rows)
        TicketTenderRow(
          amountInCents: (r['total'] as int?) ?? 0,
          currency: (r['currency'] as String?) ?? '',
          rateMicros: (r['rate_micros'] as int?) ?? 1000000,
          pivotCurrency:
              (r['pivot_currency'] as String?) ??
              (r['currency'] as String?) ??
              '',
        ),
    ];
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
        // L'encaisseur attribué par le SERVEUR (v29). Il descend là où les
        // `cashier_*` ne descendent pas — c'est le seul nom disponible sur un
        // versement encaissé depuis une autre caisse.
        'collected_by_name',
        // Le payeur (v43) : descend et hydrate une ligne inconnue, donc
        // disponible partout, pas seulement sur le poste d'encaissement.
        'payer_first_name',
        'payer_last_name',
        'payer_middle_name',
        'payer_phone_number',
        // L'UUID de la pièce scellée (v19). C'est LUI qui dit si le ticket est
        // provisoire — affirmativement, cf. `TicketReceiptModel.isProvisional`.
        'receipt_id',
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
      collectedByName: r['collected_by_name'] as String?,
      payerFirstName: r['payer_first_name'] as String?,
      payerLastName: r['payer_last_name'] as String?,
      payerMiddleName: r['payer_middle_name'] as String?,
      payerPhoneNumber: r['payer_phone_number'] as String?,
      receiptId: r['receipt_id'] as String?,
      deviceId: r['device_id'] as String?,
      syncStatus: (r['sync_status'] as String?) ?? 'PENDING_SYNC',
    );
  }

  /// Répartition ligne à ligne, dans l'ordre d'écriture — c'est une **saisie**
  /// du guichet (A-2), pas un calcul : elle s'imprime telle quelle.
  ///
  /// ## Le libellé imprimé : le TITRE de la nature, puis le libellé gelé
  ///
  /// Le papier porte le nom du frais, pas sa tranche ni son code. Il se lit
  /// donc dans `ref_fee_code_sections` — « le titre que l'école donne à chaque
  /// nature de frais » —, qui est indexée par `(school_id, code)` et ne porte
  /// donc **aucune fraction**.
  ///
  /// ⚠️ **Avec repli sur le libellé gelé, et le repli n'est pas une
  /// précaution.** Cette table n'est remplie que par le module Configuration :
  /// son propre commentaire de schéma constate que « le cache est froid pour un
  /// caissier ». Sur une tablette où personne n'y est passé, elle est **vide**.
  /// Le papier garde alors `organisation materiels examens - 1/3`, ce qui reste
  /// juste — là où un ticket qui ne nommerait plus le frais ne le serait pas.
  ///
  /// ⚠️ **Et surtout : on ne découpe RIEN sur le tiret.** « Frais mi-parcours -
  /// session 2 » y perdrait sa moitié utile, et rien ne distingue ce tiret-là
  /// d'un séparateur de tranche. Une troncature serait un défaut silencieux sur
  /// un papier remis à une famille.
  ///
  /// Le **code de tranche** (`(OM1)`) ne s'imprime plus : il était composé ici
  /// pour distinguer deux versements sur deux tranches d'un même minerval, et
  /// le porteur a arbitré que le nom du frais suffit sur un reçu.
  ///
  /// ⚠️ **`LEFT JOIN`, jamais `JOIN`** : le tarif comme le titre peuvent avoir
  /// quitté l'appareil, et perdre une ligne de répartition sur un ticket, c'est
  /// remettre à une famille un papier dont le détail ne fait plus la somme.
  ///
  /// ## Une ligne par (nature, devise), et pourquoi ce regroupement existe
  ///
  /// Retirer le code de tranche sans regrouper faisait sortir **trois lignes
  /// identiques** quand un versement solde trois tranches d'un même frais —
  /// pire qu'avant, puisque `(OM1)` était précisément ce qui les distinguait.
  /// Rien ne l'interdit en base : `payment_allocations` n'a aucune contrainte
  /// d'unicité sur `(payment_id, fee_code)`, et payer plusieurs tranches d'un
  /// coup est le geste nominal du guichet.
  ///
  /// ⚠️ **La devise entre dans la clé.** Grouper sur le seul code additionnerait
  /// des francs et des dollars — « le chiffre qui n'est l'argent de personne »
  /// que ce gabarit refuse partout ailleurs.
  ///
  /// ⚠️ **Le libellé retenu est le PREMIER du groupe, et « premier » est
  /// défini.** Deux tranches sans titre de section peuvent porter deux libellés
  /// figés différents (« … - 1/3 », « … - 2/3 »). Un `GROUP BY` SQL rendrait
  /// alors la valeur d'une ligne quelconque : le ticket étant **librement
  /// réimprimable**, deux tirages du même versement porteraient deux intitulés
  /// différents, sur des papiers qu'une famille garde côte à côte. D'où un tri
  /// **total** — `rowid` pour l'ordre d'écriture, `id` pour le rendre strict —
  /// et un regroupement écrit en Dart, où le choix se lit.
  ///
  /// L'école est résolue par sous-requête sur `ref_school` — cache mono-ligne,
  /// même lecture que partout ailleurs dans ce DAO.
  Future<List<TicketAllocationRow>> findAllocations(String paymentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.fee_code,
             pa.currency,
             pa.amount_in_cents,
             COALESCE(
               NULLIF(TRIM(s.label), ''),
               NULLIF(TRIM(pa.student_charge_label), ''),
               pa.fee_code
             ) AS label
      FROM payment_allocations pa
      LEFT JOIN ref_fee_code_sections s
        ON UPPER(s.code) = UPPER(pa.fee_code)
       AND s.school_id = (SELECT id FROM ref_school LIMIT 1)
      WHERE pa.payment_id = ?
      ORDER BY pa.rowid, pa.id
      ''',
      [paymentId],
    );

    // Regroupement en Dart plutôt qu'en SQL, pour que le choix du libellé soit
    // EXPLICITE : un `GROUP BY` rendrait, pour une colonne non agrégée, la
    // valeur d'une ligne quelconque du groupe — c'est-à-dire un libellé
    // non déterministe.
    final grouped = <String, TicketAllocationRow>{};
    for (final r in rows) {
      final currency = (r['currency'] as String?) ?? '';
      final key = '${(r['fee_code'] as String?) ?? ''}|$currency';
      final amount = (r['amount_in_cents'] as int?) ?? 0;
      final existing = grouped[key];
      grouped[key] = TicketAllocationRow(
        // Le PREMIER libellé du groupe, dans l'ordre où la requête les rend —
        // lequel est total (`rowid, id`), donc reproductible.
        label: existing?.label ?? ((r['label'] as String?) ?? ''),
        amountInCents: (existing?.amountInCents ?? 0) + amount,
        currency: currency,
      );
    }
    return grouped.values.toList(growable: false);
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

  /// Les titres de nature de frais de l'école, `code` en MAJUSCULES → libellé.
  ///
  /// Même source que la répartition (`ref_fee_code_sections`), et pour la même
  /// raison : le solde détaillé doit nommer les frais **exactement comme** la
  /// ventilation juste au-dessus. Deux noms pour un même code sur le même
  /// papier feraient chercher au parent la différence entre eux.
  ///
  /// Table vide ⇒ carte vide, et l'appelant retombe sur le libellé de la
  /// créance. Elle n'est peuplée que par Configuration : cf. la note de
  /// [findAllocations].
  Future<Map<String, String>> feeSectionTitles() async {
    final rows = await _db.rawQuery(
      'SELECT code, label FROM ref_fee_code_sections '
      'WHERE school_id = (SELECT id FROM ref_school LIMIT 1)',
    );
    return {
      for (final r in rows)
        if (((r['code'] as String?) ?? '').trim().isNotEmpty &&
            ((r['label'] as String?) ?? '').trim().isNotEmpty)
          (r['code'] as String).trim().toUpperCase(): (r['label'] as String)
              .trim(),
    };
  }

  /// Numéro **définitif** du reçu, `null` tant que la pièce n'est pas scellée.
  ///
  /// C'est l'ACK qui pose les deux ensemble (`number` = numéro serveur,
  /// `status` = `DEFINITIVE`) : lire `number` sans vérifier le statut rendrait
  /// le numéro PROVISOIRE sur une pièce non scellée, puisque c'est lui qui
  /// occupe la colonne avant l'ACK.
  ///
  /// ⚠️ **`null` ne veut pas dire « pas scellé ».** Un versement encaissé sur
  /// une AUTRE caisse n'a aucune ligne `generated_documents` locale, et rend donc
  /// `null` alors qu'il est parfaitement scellé côté serveur. C'est exactement
  /// pourquoi le caractère provisoire du ticket se lit sur `payments.receipt_id`
  /// — qui descend, lui — et jamais sur l'absence de ce numéro.
  Future<String?> findDefinitiveNumber(String paymentId) async {
    final rows = await _db.query(
      'generated_documents',
      columns: const ['number', 'status'],
      where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
      whereArgs: [paymentId, 'PAYMENT', 'RC'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    if (rows.first['status'] != 'DEFINITIVE') return null;
    final number = (rows.first['number'] as String?)?.trim();
    return (number != null && number.isNotEmpty) ? number : null;
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

  /// En-tête complet de l'établissement (zone Z1). `null` tant que le
  /// référentiel n'a pas été pullé.
  ///
  /// Les six colonnes sont lues d'un coup parce que l'en-tête les imprime toutes
  /// : la requête ne coûte pas plus, et un champ oublié ici ne se verrait qu'au
  /// papier, sur une ligne manquante que rien ne signale.
  Future<TicketSchoolRow?> findSchool() async {
    final rows = await _db.query(
      'ref_school',
      columns: const [
        'name',
        'address',
        'municipality',
        'city',
        'email',
        'phone',
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final r = rows.first;
    return TicketSchoolRow(
      name: (r['name'] as String?) ?? '',
      address: r['address'] as String?,
      municipality: r['municipality'] as String?,
      city: r['city'] as String?,
      email: r['email'] as String?,
      phone: r['phone'] as String?,
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

  /// L'encaisseur tel que le SERVEUR l'attribue (v29), distinct des `cashier_*`
  /// que ce poste a stampés au guichet.
  final String? collectedByName;

  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;
  final String? payerPhoneNumber;

  /// UUID de la pièce scellée (v19). `null` = pas encore scellée.
  final String? receiptId;

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
    this.collectedByName,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.receiptId,
    this.deviceId,
    required this.syncStatus,
  });

  /// Nom affichable du caissier — les `cashier_*` stampés ICI d'abord, **puis
  /// l'attribution serveur**.
  ///
  /// Le repli n'est pas cosmétique : le patch de pull ne touche jamais aux
  /// `cashier_*` (« ce que ce poste a imprimé sur le ticket ne se réécrit pas
  /// depuis le réseau »), si bien qu'un versement encaissé sur une AUTRE caisse
  /// n'en a aucun. Sans ce repli, son ticket sortirait sans caissier — or sur
  /// une pièce non scellée, l'imputabilité humaine remplace l'imputabilité
  /// cryptographique (RG-012-11), et un papier que personne ne signe ne
  /// s'arbitre pas en fin de journée.
  ///
  /// L'ordre compte : ce que ce poste a écrit fait autorité sur ce que le
  /// serveur a déduit, jamais l'inverse.
  String? get cashierFullName {
    final parts = [
      cashierFirstName?.trim(),
      cashierLastName?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    if (parts.isNotEmpty) return parts.join(' ');
    final attributed = collectedByName?.trim();
    return (attributed != null && attributed.isNotEmpty) ? attributed : null;
  }

  /// Nom composé du payeur — **`null`, jamais `''`**.
  ///
  /// C'est cette distinction que le gabarit lit pour escamoter le bloc payeur
  /// ENTIER : sur une pièce, une mention laissée vide se lit comme une mention
  /// effacée et invite à chercher ce qu'on aurait retiré.
  String? get payerFullName {
    final parts = [
      payerLastName?.trim(),
      payerMiddleName?.trim(),
      payerFirstName?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Ce versement a-t-il quelqu'un à nommer comme payeur ?
  ///
  /// **Un téléphone seul suffit** : il a été tapé, donc il désigne quelqu'un.
  /// Même règle que le ticket de vente boutique, et il le faut — deux pièces du
  /// même acte qui divergent se paient au rapprochement de caisse.
  bool get hasPayer =>
      payerFullName != null || (payerPhoneNumber?.trim().isNotEmpty ?? false);
}

/// Une ligne de `payment_tenders`, telle que le ticket la lit.
class TicketTenderRow {
  final int amountInCents;
  final String currency;
  final int rateMicros;
  final String pivotCurrency;

  const TicketTenderRow({
    required this.amountInCents,
    required this.currency,
    required this.rateMicros,
    required this.pivotCurrency,
  });
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
  final String? address;
  final String? municipality;
  final String? city;
  final String? email;
  final String? phone;

  const TicketSchoolRow({
    required this.name,
    this.address,
    this.municipality,
    this.city,
    this.email,
    this.phone,
  });

  /// La ligne « ville » de l'en-tête — **la ville d'abord, la commune à défaut**.
  ///
  /// Remplace l'ancien `locality`, qui repliait les deux dans une ligne unique
  /// coiffant l'adresse. L'en-tête les sépare désormais : l'adresse a sa ligne,
  /// celle-ci porte la localité.
  ///
  /// ⚠️ **La priorité est inversée par rapport à l'ancien getter**, et c'est
  /// délibéré. L'en-tête demande « la ville » ; et `School.locality`, qui titre
  /// la bannière d'accueil, prend déjà la ville en premier. Les deux divergeaient
  /// : la même tablette pouvait imprimer « Ngaliema » et afficher « Kinshasa ».
  /// Le repli sur la commune reste, sans quoi une école qui ne renseigne que
  /// celle-ci perdrait sa localité — le référentiel autorise les deux.
  String? get locality {
    final town = city?.trim();
    if (town != null && town.isNotEmpty) return town;
    final commune = municipality?.trim();
    return (commune != null && commune.isNotEmpty) ? commune : null;
  }
}
