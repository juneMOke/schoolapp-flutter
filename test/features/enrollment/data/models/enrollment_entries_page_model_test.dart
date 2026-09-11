import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/enrollment_entries_page_model.dart';

Map<String, dynamic> _entryJson() => <String, dynamic>{
  'enrollmentId': 'e1',
  'studentId': 's1',
  'firstName': 'Amina',
  'lastName': 'KABILA',
  'surname': 'Nsimba',
  'gender': 'FEMALE',
  'schoolLevelId': 'lvl',
  'schoolLevel': '6e année',
  'cycle': 'PRIMARY',
  'formerStudent': true,
  'enrollmentDate': '2026-09-05',
  'createdAt': '2026-09-05T09:30:00',
  'recordedBy': 'M. Ilunga',
};

/// **Le numéro de page s'appelle `number`** — et s'il n'est pas lu, la
/// pagination de l'écran n'avance jamais.
void main() {
  test('la Page Spring brute : `number` est LU', () {
    // La forme que sert `/entries` aujourd'hui. Lire `page` ici rendait
    // toujours 0 : « suivant » redemandait la page 1 sans fin.
    final page = EnrollmentEntriesPageModel.fromJson(<String, dynamic>{
      'content': <dynamic>[_entryJson()],
      'pageable': <String, dynamic>{'pageNumber': 2, 'pageSize': 8},
      'number': 2,
      'size': 8,
      'totalElements': 30,
      'totalPages': 4,
      'first': false,
      'last': false,
      'numberOfElements': 1,
      'empty': false,
    }).toEntity();

    expect(page.page, 2);
    expect(page.size, 8);
    expect(page.totalElements, 30);
    expect(page.totalPages, 4);
    expect(page.content.single.displayName, 'KABILA Nsimba Amina');
  });

  test('le PagedModel de Spring Data : tout est rangé sous `page`', () {
    // La forme vers laquelle le serveur peut basculer d'une ligne de
    // configuration. Sans elle, `json['page'] as int` aurait levé.
    final page = EnrollmentEntriesPageModel.fromJson(<String, dynamic>{
      'content': <dynamic>[],
      'page': <String, dynamic>{
        'size': 8,
        'number': 3,
        'totalElements': 30,
        'totalPages': 4,
      },
    }).toEntity();

    expect(page.page, 3);
    expect(page.size, 8);
    expect(page.totalElements, 30);
    expect(page.totalPages, 4);
  });

  test('un DTO de page maison : `page` est un entier à la racine', () {
    final page = EnrollmentEntriesPageModel.fromJson(<String, dynamic>{
      'content': <dynamic>[],
      'page': 1,
      'size': 8,
      'totalElements': 12,
      'totalPages': 2,
    }).toEntity();

    expect(page.page, 1);
    expect(page.totalPages, 2);
  });

  test('rien d\'annoncé : première page, zéro partout — jamais une levée', () {
    final page = EnrollmentEntriesPageModel.fromJson(
      const <String, dynamic>{},
    ).toEntity();

    expect(page.page, 0);
    expect(page.content, isEmpty);
    expect(page.totalElements, 0);
    expect(page.totalPages, 0);
  });
}
