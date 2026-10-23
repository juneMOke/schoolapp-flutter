import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_beneficiary_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_history_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

Future<void> _sale(
  Database db,
  String id, {
  required String soldAt,
  String status = 'SYNCED',
  String school = 'E1',
}) => db.insert('boutique_sales', {
  'id': id,
  'school_id': school,
  'academic_year_id': 'ay-1',
  'payer_last_name': 'Ndombo',
  'sold_at': soldAt,
  'sync_status': status,
  'updated_at': 0,
});

Future<void> _line(
  Database db,
  String saleId, {
  String articleId = 'art-polo',
  int quantity = 1,
  int total = 1000,
  String currency = 'USD',
}) => db.insert('boutique_sale_lines', {
  'id': '$saleId-$articleId',
  'sale_id': saleId,
  'article_id': articleId,
  'article_label': 'Polo',
  'quantity': quantity,
  'unit_price_in_cents': total,
  'line_total_in_cents': total,
  'currency': currency,
  'position': 0,
});

/// Les lectures LOCALES du tableau de bord : tickets provisoires et dernières
/// ventes, bornées dans le jour de l'école.
void main() {
  late Database db;
  late BoutiqueHistoryRepositoryImpl repo;
  // Du 20 au 21 octobre, jours de Kinshasa : [19 23:00Z, 21 23:00Z[.
  final window = DashboardWindow(
    from: DateTime(2026, 10, 20),
    to: DateTime(2026, 10, 21),
  );

  setUp(() async {
    db = await openFullOfflineDb();
    repo = BoutiqueHistoryRepositoryImpl(
      dao: BoutiqueSaleHistoryDao(db),
      beneficiaries: BoutiqueSaleBeneficiaryDao(db),
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'E1'),
      now: DateTime.now,
    );
    await db.insert('ref_boutique_articles', {
      'id': 'art-polo',
      'school_id': 'E1',
      'academic_year_id': 'ay-1',
      'code': 'POLO',
      'label': 'Polo',
      'family': 'UNIFORME',
      'pricing_mode': 'PRIX_UNIQUE',
      'currency': 'USD',
    });
  });
  tearDown(() async => db.close());

  test('seules les ventes non acceptées sont provisoires', () async {
    await _sale(
      db,
      'en-file',
      soldAt: '2026-10-21T09:00:00.000Z',
      status: 'PENDING_SYNC',
    );
    await _sale(
      db,
      'en-echec',
      soldAt: '2026-10-21T10:00:00.000Z',
      status: 'FAILED',
    );
    await _sale(db, 'acceptee', soldAt: '2026-10-21T11:00:00Z');
    for (final id in ['en-file', 'en-echec', 'acceptee']) {
      await _line(db, id);
    }

    final provisional = (await repo.provisionalSales(
      academicYearId: 'ay-1',
      window: window,
    )).getOrElse(() => throw StateError('échec'));

    expect(provisional.lines.map((l) => l.saleId), ['en-file', 'en-echec']);
    expect(provisional.lines.first.family, ArticleFamily.uniforme);
    expect(provisional.lines.first.soldAt, DateTime.utc(2026, 10, 21, 9));
  });

  test('article retiré du catalogue : la ligne reste, sans famille', () async {
    await _sale(
      db,
      'p',
      soldAt: '2026-10-21T09:00:00.000Z',
      status: 'PENDING_SYNC',
    );
    await _line(db, 'p', articleId: 'art-disparu');

    final lines = (await repo.provisionalSales(
      academicYearId: 'ay-1',
      window: window,
    )).getOrElse(() => throw StateError('échec')).lines;
    expect(lines.single.family, isNull);
  });

  test(
    'les bornes sont celles de Kinshasa, formats local et serveur mêlés',
    () async {
      // 23 h 30 UTC le 19 = 0 h 30 le 20 à l'école : DEDANS, écrit par le delta.
      await _sale(
        db,
        'debut',
        soldAt: '2026-10-19T23:30:00Z',
        status: 'PENDING_SYNC',
      );
      // 23 h 00 UTC le 21 pile = minuit le 22 à l'école : DEHORS.
      await _sale(
        db,
        'apres',
        soldAt: '2026-10-21T23:00:00.000Z',
        status: 'PENDING_SYNC',
      );
      // 22 h 59 UTC le 19 = 23 h 59 le 19 à l'école : DEHORS.
      await _sale(
        db,
        'avant',
        soldAt: '2026-10-19T22:59:00.000Z',
        status: 'PENDING_SYNC',
      );
      for (final id in ['debut', 'apres', 'avant']) {
        await _line(db, id);
      }

      final latest = (await repo.latestSales(
        academicYearId: 'ay-1',
        window: window,
        limit: 6,
      )).getOrElse(() => throw StateError('échec'));
      expect(latest.map((s) => s.id), ['debut']);
    },
  );

  test(
    'les dernières ventes : la plus récente en tête, au plus N, école seule',
    () async {
      for (var i = 0; i < 8; i++) {
        await _sale(db, 's$i', soldAt: '2026-10-21T0$i:00:00.000Z');
        await _line(db, 's$i');
      }
      await _sale(
        db,
        'voisine',
        soldAt: '2026-10-21T09:00:00.000Z',
        school: 'E2',
      );

      final latest = (await repo.latestSales(
        academicYearId: 'ay-1',
        window: window,
        limit: 6,
      )).getOrElse(() => throw StateError('échec'));
      expect(latest.map((s) => s.id), ['s7', 's6', 's5', 's4', 's3', 's2']);
    },
  );
}
