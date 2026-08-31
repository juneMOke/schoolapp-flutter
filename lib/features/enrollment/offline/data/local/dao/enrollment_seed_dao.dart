import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Viviers de (ré)inscription : cohorte N-1 (`ref_previous_year_students`) et
/// préinscriptions (`ref_pre_enrollments`). Porte à la fois les **écritures de
/// pull** (remplacement cohorte / upsert préinscriptions) et les **lectures de
/// seed** (photo de départ des brouillons RE/PRE), plus la résolution de
/// l'année courante qui **scope par saison** ces viviers.
class EnrollmentSeedDao {
  final Database _db;

  const EnrollmentSeedDao(this._db);

  /// Remplace la cohorte N-1 (`ref_previous_year_students`). Sémantique
  /// snapshot : la cohorte est bornée/statique (pull complet always-200 à chaque
  /// cycle online, jamais de 304), le remplacement intégral évacue les radiés.
  /// Un 200 avec liste vide VIDE donc la table (cohorte réellement vidée côté
  /// serveur). Renvoie le nombre de lignes affectées : insérées, ou **purgées**
  /// quand le snapshot est vide (un wipe est un vrai changement local, pas un
  /// `notModified`).
  Future<int> replaceReenrollmentCohort(
    List<ReenrollmentCandidateDto> items, {
    required int syncedAt,
  }) async {
    var affected = items.length;
    await _db.transaction((txn) async {
      final removed = await txn.delete('ref_previous_year_students');
      // La fille se vide avec la mère : une ligne d'arriéré orpheline
      // ressortirait sur un élève que la cohorte ne porte plus.
      await txn.delete('ref_previous_year_student_balances');
      if (items.isEmpty) affected = removed;
      final batch = txn.batch();
      for (final c in items) {
        batch.insert(
          'ref_previous_year_students',
          {
            'student_id': c.studentId,
            'matriculation_number': c.matriculationNumber,
            'first_name': c.firstName,
            'last_name': c.lastName,
            'surname': c.surname,
            'gender': c.gender,
            'date_of_birth': c.dateOfBirth,
            'birth_place': c.birthPlace,
            'previous_academic_year_id': c.previousAcademicYearId,
            'previous_school_level_id': c.previousSchoolLevelId,
            'previous_classroom_id': c.previousClassroomId,
            'guardian_name': c.guardianName,
            'guardian_phone': c.guardianPhone,
            'medical_notes': c.medicalNotes,
            'synced_at': syncedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Les arriérés vivent dans la table fille, une ligne par devise. Aucune
        // ligne = ne doit rien : on n'écrit pas un zéro dans une unité que
        // personne n'a choisie.
        for (final balance in c.previousBalances) {
          batch.insert(
            'ref_previous_year_student_balances',
            {
              'student_id': c.studentId,
              'currency': balance.currency,
              'amount_in_cents': balance.amountInCents,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
    return affected;
  }

  /// Upsert delta des préinscriptions (`ref_pre_enrollments`). `updated_at`
  /// ISO-8601 du serveur converti en epoch ms local (colonne INTEGER) — le
  /// curseur de pull, lui, reste le `serverTime` opaque (jamais cette colonne).
  Future<int> upsertPreEnrollments(
    List<PreEnrollmentDto> items, {
    required int syncedAt,
  }) async {
    await applyInBatches(
      _db,
      items,
      apply: (txn, chunk) async {
        final batch = txn.batch();
        for (final p in chunk) {
          batch.insert('ref_pre_enrollments', {
            'id': p.id,
            'first_name': p.firstName,
            'last_name': p.lastName,
            'surname': p.surname,
            'gender': p.gender,
            'date_of_birth': p.dateOfBirth,
            'birth_place': p.birthPlace,
            'desired_school_level_id': p.desiredSchoolLevelId,
            'guardian_name': p.guardianName,
            'guardian_phone': p.guardianPhone,
            'updated_at': isoToEpochMillis(p.updatedAt, fallback: syncedAt),
            'synced_at': syncedAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      },
    );
    return items.length;
  }

  /// Vide `ref_pre_enrollments` **en entier**. Rend le nombre de lignes ôtées.
  ///
  /// Le seul appelant légitime est le changement d'école
  /// (`PreEnrollmentsSchoolGuard`), et l'effacement y est **total** : la table
  /// ne porte pas de colonne `school_id`, donc rien ici ne permet de ne retirer
  /// que les lignes de l'établissement sortant.
  ///
  /// ⚠️ Ne JAMAIS purger par âge ni par ancienneté. Depuis la bascule dure du
  /// seed vers le local, cette table est la **seule** source d'amorçage d'un
  /// brouillon de préinscription — il n'existe plus aucun repli GET serveur. Une
  /// ligne ôtée sans que le curseur keyset soit rembobiné dans le même geste
  /// devient définitivement inatteignable : le curseur est en avance sur elle,
  /// le serveur répondra « rien de neuf », et plus rien ne la redemandera.
  /// Purge et `SyncMetaDao.deleteCursorsOf` vont donc ensemble, ou la purge
  /// ampute.
  Future<int> deleteAllPreEnrollments() => _db.delete('ref_pre_enrollments');

  // ── Lectures (seed RE/PRE depuis le local) ──────────────────────────────────

  /// `id` de l'année académique **courante** (`is_current = 1`) telle que
  /// peuplée par le pull référentiel. `null` = référentiel non encore synchronisé
  /// (base fraîche / hors-ligne). Sert à **scoper par saison** le marqueur de
  /// skip de la cohorte N-1 (invalidation automatique au rollover d'année).
  Future<String?> findCurrentAcademicYearId() async {
    final rows = await _db.query(
      'ref_academic_years',
      columns: ['id'],
      where: 'is_current = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  /// `SELECT` enrichi du vivier N-1 : ajoute le libellé du niveau/cycle N-1
  /// (résolus depuis `previous_school_level_id`, le backend ne renvoie que
  /// l'id) et le nom de l'école COURANTE (`ref_school`, ligne unique) —
  /// réutilisé comme « établissement précédent » car une réinscription se
  /// fait forcément dans la même école. `LEFT JOIN` : un référentiel N-1 purgé
  /// (année sortie du scope courant/précédent) dégrade en `NULL`, jamais en
  /// échec de lecture.
  static const _candidateSelect = '''
    SELECT
      rpys.*,
      rsl.name AS previous_level_name,
      rslg.name AS previous_level_group_name,
      (SELECT name FROM ref_school LIMIT 1) AS current_school_name
    FROM ref_previous_year_students rpys
    LEFT JOIN ref_school_levels rsl ON rsl.id = rpys.previous_school_level_id
    LEFT JOIN ref_school_level_groups rslg ON rslg.id = rsl.level_group_id
  ''';

  /// Candidat de réinscription par `student_id` canonique (photo de départ du
  /// brouillon RE). `null` = cohorte non peuplée (pull dormant) ou élève absent.
  Future<ReenrollmentCandidate?> findReenrollmentCandidateByStudentId(
    String studentId,
  ) async {
    final rows = await _db.rawQuery(
      '$_candidateSelect WHERE rpys.student_id = ? LIMIT 1',
      [studentId],
    );
    if (rows.isEmpty) return null;
    final balances = await _balancesOf([studentId]);
    return _candidateFromRow(rows.first, balances[studentId] ?? MoneyBag.empty);
  }

  /// Recherche des candidats à la réinscription (vivier N-1) filtrée par niveau.
  /// La cohorte ne stocke que `previous_school_level_id` : le filtre par *groupe*
  /// passe donc par les niveaux de ce groupe (référentiel local
  /// `ref_school_levels`). Le raffinage nom/DOB reste côté présentation (parité
  /// avec `searchByAcademicInfo`). Trié par nom pour une liste stable.
  Future<List<ReenrollmentCandidate>> searchReenrollmentCandidates({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (schoolLevelId != null) {
      clauses.add('rpys.previous_school_level_id = ?');
      args.add(schoolLevelId);
    } else if (schoolLevelGroupId != null) {
      clauses.add(
        'rpys.previous_school_level_id IN '
        '(SELECT id FROM ref_school_levels WHERE level_group_id = ?)',
      );
      args.add(schoolLevelGroupId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db.rawQuery(
      '$_candidateSelect $where ORDER BY rpys.last_name, rpys.first_name',
      args,
    );
    final balances = await _balancesOf([
      for (final r in rows) r['student_id'] as String,
    ]);
    return [
      for (final r in rows)
        _candidateFromRow(r, balances[r['student_id']] ?? MoneyBag.empty),
    ];
  }

  /// Arriérés N-1 des élèves demandés, groupés par élève.
  ///
  /// Une requête pour tout le lot plutôt qu'une par candidat : la liste de
  /// réinscription se lit d'un coup, et N+1 requêtes sur une tablette se
  /// sentent.
  Future<Map<String, MoneyBag>> _balancesOf(List<String> studentIds) async {
    if (studentIds.isEmpty) return const {};
    final placeholders = List.filled(studentIds.length, '?').join(', ');
    final rows = await _db.rawQuery(
      'SELECT student_id, currency, amount_in_cents '
      'FROM ref_previous_year_student_balances '
      'WHERE student_id IN ($placeholders) '
      'ORDER BY student_id, currency',
      studentIds,
    );
    final byStudent = <String, List<Money>>{};
    for (final r in rows) {
      (byStudent[r['student_id'] as String] ??= <Money>[]).add(
        Money.parse(
          (r['amount_in_cents'] as int?) ?? 0,
          (r['currency'] as String?) ?? '',
        ),
      );
    }
    return {
      for (final entry in byStudent.entries)
        entry.key: MoneyBag.of(entry.value),
    };
  }

  ReenrollmentCandidate _candidateFromRow(
    Map<String, Object?> r,
    MoneyBag balances,
  ) => ReenrollmentCandidate(
    studentId: r['student_id'] as String,
    matriculationNumber: r['matriculation_number'] as String,
    firstName: r['first_name'] as String,
    lastName: r['last_name'] as String,
    surname: r['surname'] as String?,
    gender: r['gender'] as String,
    dateOfBirth: r['date_of_birth'] as String,
    birthPlace: r['birth_place'] as String?,
    previousAcademicYearId: r['previous_academic_year_id'] as String?,
    previousSchoolLevelId: r['previous_school_level_id'] as String?,
    previousClassroomId: r['previous_classroom_id'] as String?,
    guardianName: r['guardian_name'] as String?,
    guardianPhone: r['guardian_phone'] as String?,
    previousBalances: balances,
    medicalNotes: r['medical_notes'] as String?,
    previousSchoolLevelName: r['previous_level_name'] as String?,
    previousSchoolLevelGroupName: r['previous_level_group_name'] as String?,
    previousSchoolName: r['current_school_name'] as String?,
  );

  /// Préinscription par `id` (photo de départ du brouillon PRE). `null` =
  /// snapshot non peuplé (pull dormant) ou préinscription absente.
  Future<PreEnrollmentCandidate?> findPreEnrollmentById(String id) async {
    final rows = await _db.query(
      'ref_pre_enrollments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _preEnrollmentFromRow(rows.first);
  }

  /// Recherche des candidats à la pré-inscription (vivier `ref_pre_enrollments`)
  /// filtrée par niveau souhaité. Pas de `LEFT JOIN` référentiel ici
  /// (contrairement à [searchReenrollmentCandidates]) : une préinscription n'a
  /// pas d'établissement précédent à préremplir, seulement un niveau souhaité
  /// brut (`desired_school_level_id`, potentiellement `NULL` — un tel candidat
  /// ne remonte alors que sans filtre). Le raffinage nom/DOB reste côté
  /// présentation. Trié par nom pour une liste stable.
  Future<List<PreEnrollmentCandidate>> searchPreEnrollmentCandidates({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (schoolLevelId != null) {
      clauses.add('desired_school_level_id = ?');
      args.add(schoolLevelId);
    } else if (schoolLevelGroupId != null) {
      clauses.add(
        'desired_school_level_id IN '
        '(SELECT id FROM ref_school_levels WHERE level_group_id = ?)',
      );
      args.add(schoolLevelGroupId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db.rawQuery(
      'SELECT * FROM ref_pre_enrollments $where ORDER BY last_name, first_name',
      args,
    );
    return rows.map(_preEnrollmentFromRow).toList();
  }

  PreEnrollmentCandidate _preEnrollmentFromRow(Map<String, Object?> r) =>
      PreEnrollmentCandidate(
        id: r['id'] as String,
        firstName: r['first_name'] as String,
        lastName: r['last_name'] as String,
        surname: r['surname'] as String?,
        gender: r['gender'] as String?,
        dateOfBirth: r['date_of_birth'] as String?,
        birthPlace: r['birth_place'] as String?,
        desiredSchoolLevelId: r['desired_school_level_id'] as String?,
        guardianName: r['guardian_name'] as String?,
        guardianPhone: r['guardian_phone'] as String?,
      );
}
