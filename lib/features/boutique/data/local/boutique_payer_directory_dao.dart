import 'package:school_app_flutter/core/database/phone_number_sql.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le répertoire des payeurs de la caisse — **une projection des ventes**, pas
/// une table de personnes.
///
/// Le payeur n'a aucun identifiant dans le domaine : il n'existe que comme
/// identité recopiée sur chaque vente. Deux ventes du même parent sont deux
/// écritures indépendantes, et c'est pourquoi le rapprochement se fait sur une
/// clé dérivée du **numéro** — jamais sur un id.
///
/// **Autonome, et non déduit de l'effectif.** Le payeur n'est pas forcément un
/// parent d'élève : un ancien élève qui retire son dossier paye pour lui-même.
///
/// **Isolé du répertoire de la Facturation** (invariant I-4) : les croiser
/// donnerait un annuaire plus riche dès le premier jour, mais exigerait
/// `finance.payment.read` — que le caissier boutique n'a pas nécessairement — et
/// ouvrirait une dépendance que l'isolation du module existe à empêcher.
class BoutiquePayerDirectoryDao {
  final Database _db;

  const BoutiquePayerDirectoryDao(this._db);

  /// Plafond de lignes scannées avant le tri en Dart.
  ///
  /// En recherche par identité, aucune clause SQL ne restreint les lignes : ce
  /// plafond est la seule chose qui borne le travail sur une caisse qui tourne
  /// depuis des mois.
  static const int searchScanCap = 400;

  /// Les payeurs de cette école dont le numéro se rapproche de [phoneNumber].
  ///
  /// Rend une liste vide sous le seuil de chiffres significatifs : **on ne juge
  /// pas un numéro à moitié tapé**, et proposer sur trois chiffres remonterait
  /// la moitié du répertoire.
  Future<List<BoutiquePayer>> findByPhone({
    required String schoolId,
    required String phoneNumber,
    int limit = 5,
  }) async {
    final national = PhoneNumberFormat.nationalPartOf(phoneNumber.trim());
    if (national.isEmpty) return const [];

    final rows = await _db.rawQuery(
      'SELECT payer_last_name, payer_middle_name, payer_first_name, '
      '       payer_phone_number, payer_name, '
      '       COUNT(*) AS sale_count, MAX(sold_at) AS last_sold_at '
      '  FROM boutique_sales '
      ' WHERE school_id = ? '
      '   AND payer_phone_number IS NOT NULL '
      "   AND ${PhoneNumberSql.digitsOnly('payer_phone_number')} LIKE ? "
      ' GROUP BY payer_phone_number, payer_last_name, payer_middle_name, '
      '          payer_first_name, payer_name '
      ' ORDER BY last_sold_at DESC '
      ' LIMIT $searchScanCap',
      [schoolId, '%$national%'],
    );

    // ⚠️ Le `LIKE` n'est qu'un PRÉ-FILTRE : deux abonnés de part et d'autre du
    // fleuve (`+242…` / `+243…`) partagent leurs derniers chiffres. Le verdict
    // se rend en Dart, indicatif compris — sans quoi une vente s'attacherait au
    // payeur d'un autre pays.
    final confirmed = [
      for (final row in rows)
        if (PhoneNumberFormat.sameNumber(
          (row['payer_phone_number'] as String?) ?? '',
          phoneNumber,
        ))
          _payerOf(row),
    ];

    return _mergeByKey(confirmed).take(limit).toList(growable: false);
  }

  /// Deux lignes du même payeur — l'une saisie ici, l'autre descendue du delta
  /// et donc sans découpage — se fondent en une seule.
  ///
  /// **L'entrée découpée gagne** : c'est celle qui remplit les trois champs du
  /// formulaire, et c'est tout l'intérêt du répertoire. Le compteur, lui,
  /// additionne les deux — une vente reste une vente.
  static List<BoutiquePayer> _mergeByKey(List<BoutiquePayer> payers) {
    final merged = <String, BoutiquePayer>{};
    for (final payer in payers) {
      final key = payer.matchKey ?? payer.displayName.toLowerCase();
      final existing = merged[key];
      if (existing == null) {
        merged[key] = payer;
        continue;
      }
      merged[key] = existing.isSplit
          ? existing.withMoreSales(payer.saleCount)
          : payer.withMoreSales(existing.saleCount);
    }
    final result = merged.values.toList(growable: false)
      ..sort((a, b) => (b.lastSoldAt ?? '').compareTo(a.lastSoldAt ?? ''));
    return result;
  }

  static BoutiquePayer _payerOf(Map<String, Object?> row) {
    final lastName = (row['payer_last_name'] as String?)?.trim() ?? '';
    return BoutiquePayer(
      // Une vente descendue du delta n'a que son nom composé : on le place en
      // « Nom », les autres parties vides. Le redécouper serait une invention —
      // « Ndombo Lelo Willy » ne se redécoupe pas sans se tromper.
      lastName: lastName.isNotEmpty
          ? lastName
          : ((row['payer_name'] as String?)?.trim() ?? ''),
      middleName: (row['payer_middle_name'] as String?)?.trim() ?? '',
      firstName: (row['payer_first_name'] as String?)?.trim() ?? '',
      phoneNumber: (row['payer_phone_number'] as String?)?.trim() ?? '',
      saleCount: (row['sale_count'] as num?)?.toInt() ?? 0,
      lastSoldAt: row['last_sold_at'] as String?,
      isSplit: lastName.isNotEmpty,
    );
  }
}
