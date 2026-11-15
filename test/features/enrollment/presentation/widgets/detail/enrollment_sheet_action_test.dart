import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_sheet_action.dart';

EditiqueCacheEntry _entry(
  String id, {
  String docType = 'FI',
  String? sha = 'sha',
  int? emittedAt,
  int? edition,
  int createdAt = 1,
}) => EditiqueCacheEntry(
  id: id,
  documentId: 'doc-$id',
  documentNumber: 'ETL-FI-2526-000001',
  docType: docType,
  schoolId: 'school',
  sizeBytes: 10,
  contentSha256: sha,
  emittedAt: emittedAt,
  edition: edition,
  createdAt: createdAt,
  lastAccessedAt: 1,
);

void main() {
  test('hors ligne : la fiche la plus récente dont on a les octets', () {
    final kept = EnrollmentSheetAction.latestKeptSheet([
      _entry('old', emittedAt: 10),
      _entry('new', emittedAt: 20),
      _entry('sans-octets', emittedAt: 30, sha: null),
      _entry('attestation', docType: 'AI', emittedAt: 40),
    ]);
    expect(kept!.id, 'new');
  });

  // Une fiche corrigée garde son numéro, en édition suivante (back v0.17.0),
  // et la correction se fait souvent le jour même : le jour d'émission ne
  // départage plus rien. Les deux ordres d'entrée sont essayés, pour que le
  // test ne repose pas sur la stabilité du tri.
  test('le même jour, l édition suivante l emporte, dans les deux ordres', () {
    final first = _entry('edition-1', emittedAt: 10, createdAt: 5);
    final second = _entry('edition-2', emittedAt: 10, edition: 2, createdAt: 4);

    expect(
      EnrollmentSheetAction.latestKeptSheet([first, second])!.id,
      'edition-2',
    );
    expect(
      EnrollmentSheetAction.latestKeptSheet([second, first])!.id,
      'edition-2',
    );
  });

  test('aucune fiche gardée : rien', () {
    expect(
      EnrollmentSheetAction.latestKeptSheet([_entry('a', docType: 'AI')]),
      isNull,
    );
  });
}
