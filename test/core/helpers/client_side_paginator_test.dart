import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/client_side_paginator.dart';

void main() {
  final items = List<int>.generate(12, (i) => i);

  test('découpe la première page', () {
    final page = ClientSidePaginator.paginate(items, page: 0, size: 10);

    expect(page.content.length, 10);
    expect(page.page, 0);
    expect(page.totalElements, 12);
    expect(page.totalPages, 2);
  });

  test('la dernière page est partielle', () {
    final page = ClientSidePaginator.paginate(items, page: 1, size: 10);

    expect(page.content, [10, 11]);
    expect(page.page, 1);
  });

  test('une page hors bornes est ramenée dans les bornes', () {
    final page = ClientSidePaginator.paginate(items, page: 99, size: 10);

    expect(page.page, 1);
    expect(page.content, [10, 11]);
  });

  test('une liste vide ne fait pas lever le clamp', () {
    final page = ClientSidePaginator.paginate(<int>[], page: 3, size: 10);

    expect(page.content, isEmpty);
    expect(page.page, 0);
    expect(page.totalPages, 0);
    expect(page.totalElements, 0);
  });

  test('une taille nulle ou négative retombe sur 1', () {
    expect(ClientSidePaginator.paginate(items, page: 0, size: 0).size, 1);
    expect(ClientSidePaginator.paginate(items, page: 0, size: -5).size, 1);
    expect(
      ClientSidePaginator.paginate(items, page: 3, size: 0).content,
      [3],
    );
  });

  test('une page négative est ramenée à la première', () {
    final page = ClientSidePaginator.paginate(items, page: -4, size: 10);

    expect(page.page, 0);
  });
}
