import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';

void main() {
  group('ClassesListPageHelpers', () {
    test(
      'buildCycleOptions sorts cycles and levels while preserving classrooms',
      () {
        final bundles = [
          const BootstrapSchoolLevelGroupBundle(
            schoolLevelGroup: BootstrapSchoolLevelGroup(
              id: 'group-b',
              version: 1,
              name: 'Secondaire',
              code: 'SEC',
              periodType: 'YEAR',
              displayOrder: 2,
            ),
            schoolLevels: [
              BootstrapSchoolLevelBundle(
                schoolLevel: BootstrapSchoolLevel(
                  id: 'level-b',
                  version: 1,
                  name: '5e',
                  code: '5E',
                  displayOrder: 2,
                  splitIntoClassrooms: true,
                ),
                classrooms: [
                  BootstrapClassroom(
                    id: 'class-b',
                    version: 1,
                    schoolLevelId: 'level-b',
                    name: '5e A',
                    capacity: 30,
                    totalCount: 20,
                    femaleCount: 11,
                    maleCount: 9,
                  ),
                ],
                tariffs: [],
              ),
            ],
          ),
          const BootstrapSchoolLevelGroupBundle(
            schoolLevelGroup: BootstrapSchoolLevelGroup(
              id: 'group-a',
              version: 1,
              name: 'Primaire',
              code: 'PRI',
              periodType: 'YEAR',
              displayOrder: 1,
            ),
            schoolLevels: [
              BootstrapSchoolLevelBundle(
                schoolLevel: BootstrapSchoolLevel(
                  id: 'level-a2',
                  version: 1,
                  name: '2e',
                  code: '2E',
                  displayOrder: 2,
                  splitIntoClassrooms: false,
                ),
                classrooms: [],
                tariffs: [],
              ),
              BootstrapSchoolLevelBundle(
                schoolLevel: BootstrapSchoolLevel(
                  id: 'level-a1',
                  version: 1,
                  name: '1re',
                  code: '1RE',
                  displayOrder: 1,
                  splitIntoClassrooms: true,
                ),
                classrooms: [
                  BootstrapClassroom(
                    id: 'class-a',
                    version: 1,
                    schoolLevelId: 'level-a1',
                    name: '1re A',
                    capacity: 25,
                    totalCount: 18,
                    femaleCount: 10,
                    maleCount: 8,
                  ),
                ],
                tariffs: [],
              ),
            ],
          ),
        ];

        final result = ClassesListPageHelpers.buildCycleOptions(bundles);

        expect(result.map((cycle) => cycle.label), ['Primaire', 'Secondaire']);
        expect(result.first.levels.map((level) => level.label), ['1re', '2e']);
        expect(result.first.levels.first.classrooms.single.name, '1re A');
      },
    );

    test(
      'filterMembers applies case-insensitive filtering on all name parts',
      () {
        const cycle = ClassesListCycleOption(
          id: 'group-a',
          label: 'Primaire',
          displayOrder: 1,
          levels: [],
        );
        const level = ClassesListLevelOption(
          schoolLevelGroupId: 'group-a',
          schoolLevelGroupName: 'Primaire',
          schoolLevelId: 'level-a',
          label: '1re',
          displayOrder: 1,
          splitIntoClassrooms: true,
          classrooms: [],
        );
        const request = ClassesListSearchRequest(
          firstName: 'jean',
          lastName: 'dup',
          surname: 'cla',
          selectedCycle: cycle,
          selectedLevel: level,
          selectedClassroom: null,
        );

        const members = [
          ClassroomMember(
            id: '1',
            studentId: 'student-1',
            classroomId: 'class-1',
            academicYearId: 'year-1',
            studentFirstName: 'Jean',
            studentLastName: 'Dupont',
            studentMiddleName: 'Claude',
            studentGender: ClassroomMemberGender.male,
          ),
          ClassroomMember(
            id: '2',
            studentId: 'student-2',
            classroomId: 'class-1',
            academicYearId: 'year-1',
            studentFirstName: 'Sarah',
            studentLastName: 'Mukendi',
            studentMiddleName: 'Anne',
            studentGender: ClassroomMemberGender.female,
          ),
        ];

        final result = ClassesListPageHelpers.filterMembers(members, request);

        expect(result, hasLength(1));
        expect(result.single.id, '1');
      },
    );
  });
}
