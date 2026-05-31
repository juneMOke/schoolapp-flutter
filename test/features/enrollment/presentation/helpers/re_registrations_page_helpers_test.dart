import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/re_registrations_page_helpers.dart';

void main() {
  group('ReRegistrationsPageHelpers.buildAcademicOptions', () {
    test('sorts options by group displayOrder then level displayOrder', () {
      final bundles = [
        _bundle(
          groupId: 'g2',
          groupName: 'Second',
          groupOrder: 2,
          levels: const [
            _LevelData(id: 'l2', name: 'L2', order: 2),
            _LevelData(id: 'l1', name: 'L1', order: 1),
          ],
        ),
        _bundle(
          groupId: 'g1',
          groupName: 'First',
          groupOrder: 1,
          levels: const [_LevelData(id: 'l3', name: 'L3', order: 3)],
        ),
      ];

      final result = ReRegistrationsPageHelpers.buildAcademicOptions(bundles);

      expect(result.map((o) => o.key).toList(growable: false), [
        'g1::l3',
        'g2::l1',
        'g2::l2',
      ]);
      expect(result.map((o) => o.label).toList(growable: false), [
        'First - L3',
        'Second - L1',
        'Second - L2',
      ]);
    });

    test(
      'deduplicates duplicate group-level keys and keeps first sorted occurrence',
      () {
        final bundles = [
          _bundle(
            groupId: 'g1',
            groupName: 'Cycle A',
            groupOrder: 1,
            levels: const [
              _LevelData(id: 'l1', name: 'Level Original', order: 1),
            ],
          ),
          _bundle(
            groupId: 'g1',
            groupName: 'Cycle A Duplicate',
            groupOrder: 3,
            levels: const [
              _LevelData(id: 'l1', name: 'Level Duplicate', order: 1),
            ],
          ),
        ];

        final result = ReRegistrationsPageHelpers.buildAcademicOptions(bundles);

        expect(result, hasLength(1));
        expect(result.first.key, 'g1::l1');
        expect(result.first.label, 'Cycle A - Level Original');
      },
    );
  });
}

BootstrapSchoolLevelGroupBundle _bundle({
  required String groupId,
  required String groupName,
  required int groupOrder,
  required List<_LevelData> levels,
}) {
  return BootstrapSchoolLevelGroupBundle(
    schoolLevelGroup: BootstrapSchoolLevelGroup(
      id: groupId,
      version: 1,
      name: groupName,
      code: 'CODE-$groupId',
      periodType: 'ANNUAL',
      displayOrder: groupOrder,
    ),
    schoolLevels: levels
        .map(
          (level) => BootstrapSchoolLevelBundle(
            schoolLevel: BootstrapSchoolLevel(
              id: level.id,
              version: 1,
              name: level.name,
              code: 'CODE-${level.id}',
              displayOrder: level.order,
              splitIntoClassrooms: false,
            ),
            classrooms: const [],
            tariffs: const [],
          ),
        )
        .toList(growable: false),
  );
}

class _LevelData {
  final String id;
  final String name;
  final int order;

  const _LevelData({required this.id, required this.name, required this.order});
}
