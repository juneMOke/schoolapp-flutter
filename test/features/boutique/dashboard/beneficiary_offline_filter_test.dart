import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/beneficiary_offline_filter.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiary.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';

BoutiqueBeneficiary _student(String id, String name, String? classId) =>
    BoutiqueBeneficiary(
      studentId: id,
      fullName: name,
      classId: classId,
      classLabel: classId,
      lastPurchaseAt: DateTime.utc(2026, 10, 21, 9),
      amounts: MoneyBag.empty,
    );

/// La recherche hors ligne, rejouée sur la page en cache.
void main() {
  final window = DashboardWindow(
    from: DateTime(2026, 10, 15),
    to: DateTime(2026, 10, 21),
  );
  final cached = BoutiqueBeneficiariesPage(
    totalElements: 120,
    page: 0,
    size: 50,
    walkInLineCount: 3,
    items: [
      _student('s1', 'KABONGÉ Daniel', '6A'),
      _student('s2', 'TSHALA Grâce', '6A'),
      _student('s3', 'MWEPU David', null),
    ],
    cachedAt: DateTime(2026, 10, 20, 18),
  );

  BeneficiariesQuery query({
    String? classId,
    String? search,
    String? articleId,
  }) => BeneficiariesQuery(
    academicYearId: 'ay-1',
    window: window,
    classId: classId,
    search: search,
    articleId: articleId,
  );

  test('par nom : sans égard aux accents ni à la casse', () {
    final page = BeneficiaryOfflineFilter.apply(
      cached,
      query(search: 'kabonge'),
    )!;
    expect(page.items.map((s) => s.studentId), ['s1']);
  });

  test('par nom : ponctuation et espaces ignorés, comme le q serveur', () {
    final page = BoutiqueBeneficiariesPage(
      totalElements: 2,
      page: 0,
      size: 2,
      items: [
        _student('s1', "N'KUMBI Lelo", '6A'),
        _student('s2', 'MBALA Jean-Paul', '6A'),
      ],
    );
    List<String> idsOf(String search) => BeneficiaryOfflineFilter.apply(
      page,
      query(search: search),
    )!.items.map((s) => s.studentId).toList();

    expect(idsOf('nkumbi'), ['s1']);
    expect(idsOf('jean paul'), ['s2']);
    expect(idsOf('jeanpaul'), ['s2']);
    expect(idsOf('  '), ['s1', 's2']);
  });

  test('par classe : l\'élève non placé n\'y est pas', () {
    final page = BeneficiaryOfflineFilter.apply(cached, query(classId: '6A'))!;
    expect(page.items.map((s) => s.studentId), ['s1', 's2']);
  });

  test('le compte est celui de ce que le cache montre — rien de plus', () {
    final page = BeneficiaryOfflineFilter.apply(cached, query())!;
    expect(page.totalElements, 3);
    expect(page.hasMore, isFalse);
    // La photo ne portait que 3 élèves sur 120 : le résultat est partiel.
    expect(page.partial, isTrue);
    expect(page.cachedAt, cached.cachedAt);
  });

  test('le filtre par article ne se rejoue pas : les montants mentiraient', () {
    expect(
      BeneficiaryOfflineFilter.apply(cached, query(articleId: 'a-1')),
      isNull,
    );
  });
}
