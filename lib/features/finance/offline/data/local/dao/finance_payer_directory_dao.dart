import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/phone_number_sql.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';

/// Annuaire des payeurs, lu **100% localement** (aucun appel réseau).
///
/// C'est une exigence, pas une commodité : l'encaissement lui-même est
/// local-first et doit aboutir sur une tablette coupée du réseau. Un annuaire
/// servi par l'API tomberait précisément là où la modale, elle, continue de
/// fonctionner — et le guichetier ressaisirait tout, ce que cet écran existe
/// pour éviter.
///
/// Deux sources, jamais confondues (cf. [PayerOrigin]) :
///  - l'**historique des versements** (`payments`), fait constaté ;
///  - les **tuteurs de l'élève** (`parents` via `student_parent`), simple
///    hypothèse — un tuteur n'est pas forcément celui qui vient payer.
///
/// Lecture seule, jamais d'erreur métier : sans critère, la liste est vide.
class FinancePayerDirectoryDao {
  final Database _db;

  const FinancePayerDirectoryDao(this._db);

  /// Colonnes d'un groupe de versements partageant une identité de payeur.
  ///
  /// Le regroupement porte sur `(identité, numéro)` et non sur l'identité
  /// seule : un payeur qui a changé de numéro produit alors deux groupes, que
  /// [_mergeByIdentity] refond en gardant le **plus récent numéro connu**.
  /// Grouper sur l'identité seule aurait laissé SQLite choisir le numéro d'une
  /// ligne arbitraire du groupe.
  static const _paymentGroupSelect = '''
    SELECT
      payer_last_name   AS last_name,
      payer_first_name  AS first_name,
      payer_middle_name AS middle_name,
      payer_phone_number AS phone_number,
      MAX(paid_at)      AS last_paid_at,
      COUNT(*)          AS payment_count
    FROM payments
  ''';

  static const _paymentGroupBy = '''
    GROUP BY
      LOWER(TRIM(payer_last_name)),
      LOWER(TRIM(payer_first_name)),
      LOWER(TRIM(COALESCE(payer_middle_name, ''))),
      payer_phone_number
    ORDER BY last_paid_at DESC
  ''';

  /// Un versement sans identité exploitable n'est proposable à personne.
  static const _namedPayer =
      "TRIM(payer_last_name) <> '' AND TRIM(payer_first_name) <> ''";

  /// Payeurs à proposer d'emblée pour [studentId] : ceux qui ont déjà payé
  /// pour cet élève, puis ses tuteurs déclarés.
  ///
  /// L'ordre n'est pas cosmétique — il classe du plus sûr au plus supposé. Un
  /// tuteur qui a déjà payé n'apparaît qu'une fois, du côté constaté.
  Future<List<LocalPayerIdentity>> payersForStudent(
    String studentId, {
    int limit = 8,
  }) async {
    final rows = await _db.rawQuery(
      '$_paymentGroupSelect WHERE student_id = ? AND $_namedPayer '
      '$_paymentGroupBy',
      [studentId],
    );
    final fromPayments = _mergeByIdentity(rows.map(_payerFromPaymentRow));
    final seen = fromPayments.map((p) => p.matchKey).toSet();

    // Un tuteur qui a déjà payé est retiré du second lot, jamais du premier :
    // il doit se présenter par ce qui est CONSTATÉ (« 3 versements, dernier le
    // … ») plutôt que par la simple qualité de tuteur.
    final guardians = await _guardiansOf(studentId);
    final unseenGuardians = [
      for (final guardian in guardians)
        if (!seen.contains(guardian.matchKey)) guardian,
    ];
    return [
      ...fromPayments,
      ...unseenGuardians,
    ].take(limit).toList(growable: false);
  }

  /// Recherche d'un payeur déjà venu à la caisse, **toutes fiches élèves
  /// confondues** : le même parent paie pour sa fratrie, et le cantonner à
  /// l'élève courant le rendrait introuvable au premier versement d'un cadet.
  ///
  /// Les tuteurs n'y entrent pas : « ancien payeur » désigne ce qui a été
  /// constaté. Un tuteur qui a déjà payé y est de toute façon, par ses
  /// versements ; celui qui n'a jamais payé est proposé par
  /// [payersForStudent] sur sa propre fiche.
  ///
  /// Sans aucun critère : liste vide, sans requête.
  Future<List<LocalPayerIdentity>> searchPayers({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) async {
    final phoneDigits = PhoneNumberFormat.nationalPartOf(
      phoneNumber?.trim() ?? '',
    );
    final identityTerms = <String?>[lastName, firstName, surname]
        .map((v) => v?.trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toList(growable: false);
    if (phoneDigits.isEmpty && identityTerms.isEmpty) {
      return const <LocalPayerIdentity>[];
    }

    // Le NUMÉRO se filtre en SQL : il se réduit à des chiffres, que SQLite sait
    // comparer. L'IDENTITÉ, non — `LOWER()` n'y plie que l'ASCII, et un `LIKE`
    // sur `Kabongo` manquerait `Kabóngo`. On laisse donc SQL réduire les
    // versements à leurs payeurs DISTINCTS (quelques centaines de lignes là où
    // la table en compte des milliers) et on tranche en Dart, accents pliés.
    final clauses = <String>[_namedPayer];
    final args = <Object?>[];
    if (phoneDigits.isNotEmpty) {
      // Même pré-filtre que le rapprochement de tuteurs : la colonne peut
      // porter des écritures héritées (`0816939060`, `+243 81 693 90 60`).
      clauses.add(
        "${PhoneNumberSql.digitsOnly('payer_phone_number')} LIKE ? ESCAPE '\\'",
      );
      args.add('%${_escapeLike(phoneDigits)}%');
    }

    final rows = await _db.rawQuery(
      '$_paymentGroupSelect WHERE ${clauses.join(' AND ')} $_paymentGroupBy',
      args,
    );
    final payers = _mergeByIdentity(rows.map(_payerFromPaymentRow));
    final matching = payers.where((p) => _matchesIdentity(p, identityTerms));
    return matching.take(limit).toList(growable: false);
  }

  /// Chaque terme saisi doit se retrouver dans UNE des parties du nom (ET entre
  /// les termes) : « kabongo jean » trouve « KABONGO Jean », dans un sens comme
  /// dans l'autre, sans exiger que le guichetier sache lequel des champs porte
  /// quoi.
  static bool _matchesIdentity(LocalPayerIdentity payer, List<String> terms) {
    if (terms.isEmpty) return true;
    final haystack = SearchNormalizationHelper.normalize(payer.fullName);
    return terms.every(
      (term) =>
          haystack.contains(SearchNormalizationHelper.normalize(term.trim())),
    );
  }

  Future<List<LocalPayerIdentity>> _guardiansOf(String studentId) async {
    final rows = await _db.rawQuery(
      '''
        SELECT p.last_name, p.first_name, p.surname, p.phone_number
        FROM parents p
        INNER JOIN student_parent sp ON sp.parent_id = p.id
        WHERE sp.student_id = ?
        ORDER BY p.last_name, p.first_name
      ''',
      [studentId],
    );
    return rows
        .map(
          (r) => LocalPayerIdentity(
            lastName: (r['last_name'] as String?) ?? '',
            firstName: (r['first_name'] as String?) ?? '',
            // `parents.surname` porte le POST-NOM, que le versement nomme
            // `middle_name`. Deux mots pour la même partie du nom : les croiser
            // ici mettrait le post-nom du tuteur dans le prénom du payeur.
            middleName: _nullIfBlank(r['surname'] as String?),
            phoneNumber: _nullIfBlank(r['phone_number'] as String?),
            origin: PayerOrigin.guardian,
          ),
        )
        .where((g) => g.lastName.trim().isNotEmpty)
        .toList(growable: false);
  }

  static LocalPayerIdentity _payerFromPaymentRow(Map<String, Object?> row) =>
      LocalPayerIdentity(
        lastName: ((row['last_name'] as String?) ?? '').trim(),
        firstName: ((row['first_name'] as String?) ?? '').trim(),
        middleName: _nullIfBlank(row['middle_name'] as String?),
        phoneNumber: _nullIfBlank(row['phone_number'] as String?),
        origin: PayerOrigin.previousPayment,
        lastPaidAt: _nullIfBlank(row['last_paid_at'] as String?),
        paymentCount: (row['payment_count'] as int?) ?? 0,
      );

  /// Refond les groupes SQL en payeurs uniques, accents pliés.
  ///
  /// Les groupes arrivent du plus récent au plus ancien : le premier vu fixe
  /// l'orthographe affichée et le numéro (le plus récemment utilisé), les
  /// suivants n'apportent que leur compte de versements — et leur numéro si le
  /// plus récent n'en avait pas, cas d'un payeur dont le dernier passage est
  /// antérieur à la v28.
  static List<LocalPayerIdentity> _mergeByIdentity(
    Iterable<LocalPayerIdentity> payers,
  ) {
    final merged = <String, LocalPayerIdentity>{};
    for (final payer in payers) {
      final existing = merged[payer.matchKey];
      if (existing == null) {
        merged[payer.matchKey] = payer;
        continue;
      }
      merged[payer.matchKey] = existing.copyWith(
        phoneNumber: existing.phoneNumber ?? payer.phoneNumber,
        paymentCount: existing.paymentCount + payer.paymentCount,
      );
    }
    return merged.values.toList(growable: false);
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Neutralise les jokers `%`/`_` d'une saisie, pour qu'ils soient cherchés
  /// littéralement (même geste que `ParentSearchDao`).
  static String _escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}
