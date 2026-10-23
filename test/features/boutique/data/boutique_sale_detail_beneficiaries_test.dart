import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_beneficiary_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_history_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// La fiche d'une vente descendue de l'autre guichet : le delta ne porte que
/// l'identifiant des élèves, et le poste doit les nommer lui-même.
void main() {
  late Database db;
  late BoutiqueHistoryRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    repo = BoutiqueHistoryRepositoryImpl(
      dao: BoutiqueSaleHistoryDao(db),
      beneficiaries: BoutiqueSaleBeneficiaryDao(db),
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'E1'),
      now: DateTime.now,
    );
    await db.insert('boutique_sales', {
      'id': 'v1',
      'school_id': 'E1',
      'academic_year_id': 'ay-1',
      'sold_at': '2026-10-20T09:00:00Z',
      'sync_status': 'SYNCED',
      'updated_at': 0,
    });
  });
  tearDown(() async => db.close());

  Future<void> line(
    String id, {
    String? studentId,
    String? frozenName,
    int position = 0,
  }) => db.insert('boutique_sale_lines', {
    'id': id,
    'sale_id': 'v1',
    'article_id': 'art-polo',
    'article_label': 'Polo',
    'beneficiary_student_id': studentId,
    'beneficiary_name': frozenName,
    'quantity': 1,
    'unit_price_in_cents': 1500,
    'line_total_in_cents': 1500,
    'currency': 'USD',
    'position': position,
  });

  Future<void> student(String id, String last, String? middle, String first) =>
      db.insert('students', {
        'id': id,
        'last_name': last,
        'surname': middle,
        'first_name': first,
        'gender': 'F',
        'date_of_birth': '2015-01-01',
      });

  Future<void> placedIn(
    String studentId,
    String classroomId,
    String className, {
    String year = 'ay-1',
    String status = 'ACTIVE',
  }) async {
    await db.insert('ref_classrooms', {
      'id': classroomId,
      'academic_year_id': year,
      'name': className,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('ref_classroom_members', {
      'id': '$studentId-$classroomId',
      'student_id': studentId,
      'classroom_id': classroomId,
      'academic_year_id': year,
      'student_first_name': 'Prénom',
      'student_last_name': 'MEMBRE',
      'status': status,
    });
  }

  Future<SaleDetail> detail() async =>
      (await repo.saleDetail('v1')).getOrElse(() => throw StateError('KO'));

  test('l\'élève est nommé et placé dans sa classe de l\'année', () async {
    await line('l1', studentId: 'st-1');
    await student('st-1', 'MUKENDI', 'Kasongo', 'Grâce');
    await placedIn('st-1', 'c-6a', '6e A');

    final read = await detail();

    expect(read.beneficiaries.single.fullName, 'MUKENDI Kasongo Grâce');
    expect(read.beneficiaries.single.classLabel, '6e A');
    // La ligne aussi : c'est elle que le ticket réimprimé lit.
    expect(read.sale.lines.single.beneficiaryName, 'MUKENDI Kasongo Grâce');
  });

  test('le nom figé au guichet l\'emporte sur la fiche', () async {
    await line('l1', studentId: 'st-1', frozenName: 'MUKENDI Grâce');
    await student('st-1', 'MUKENDI', 'Kasongo', 'Grâce');

    final read = await detail();

    expect(read.beneficiaries.single.fullName, 'MUKENDI Grâce');
    expect(read.sale.lines.single.beneficiaryName, 'MUKENDI Grâce');
  });

  test('chaque élève une fois, dans l\'ordre des lignes', () async {
    await line('l1', studentId: 'st-2', position: 0);
    await line('l2', studentId: 'st-1', position: 1);
    await line('l3', studentId: 'st-2', position: 2);
    await line('l4', position: 3);
    await student('st-1', 'A', null, 'Un');
    await student('st-2', 'B', null, 'Deux');

    final read = await detail();

    expect([for (final b in read.beneficiaries) b.studentId], ['st-2', 'st-1']);
  });

  test('sans fiche élève, la place en classe donne le nom', () async {
    await line('l1', studentId: 'st-1');
    await placedIn('st-1', 'c-6a', '6e A');

    final read = await detail();

    expect(read.beneficiaries.single.fullName, 'MEMBRE Prénom');
  });

  test('la classe ACTIVE de l\'année de la vente, pas une autre', () async {
    await line('l1', studentId: 'st-1');
    await student('st-1', 'MUKENDI', null, 'Grâce');
    await placedIn('st-1', 'c-old', '5e B', year: 'ay-0');
    await placedIn('st-1', 'c-6a', '6e A', status: 'INACTIVE');
    await placedIn('st-1', 'c-6b', '6e B');

    final read = await detail();

    expect(read.beneficiaries.single.classLabel, '6e B');
  });

  test('un élève inconnu du poste reste listé, sans nom', () async {
    // L'écran le dit plutôt que de taire qu'un enfant a été servi.
    await line('l1', studentId: 'st-x');

    final read = await detail();

    expect(read.beneficiaries.single.studentId, 'st-x');
    expect(read.beneficiaries.single.fullName, isNull);
    expect(read.sale.lines.single.beneficiaryName, isNull);
  });

  test('une vente sans élève n\'en liste aucun', () async {
    await line('l1');

    expect((await detail()).beneficiaries, isEmpty);
  });
}
