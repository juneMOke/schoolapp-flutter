import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_sheet_action.dart';

EditiqueCacheEntry _entry(
  String id, {
  String docType = 'FI',
  String? sha = 'sha',
  int? emittedAt,
}) => EditiqueCacheEntry(
  id: id,
  documentId: 'doc-$id',
  docType: docType,
  schoolId: 'school',
  sizeBytes: 10,
  contentSha256: sha,
  emittedAt: emittedAt,
  createdAt: 1,
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

  test('aucune fiche gardée : rien', () {
    expect(
      EnrollmentSheetAction.latestKeptSheet([_entry('a', docType: 'AI')]),
      isNull,
    );
  });
}
