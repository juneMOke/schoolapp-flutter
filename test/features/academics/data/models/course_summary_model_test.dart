import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/course_summary_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';

void main() {
  Map<String, dynamic> buildClassroom() => <String, dynamic>{
    'id': 'c1',
    'version': 3,
    'schoolLevelId': 'lvl-1',
    'name': '6ème A',
    'capacity': 40,
    'totalCount': 32,
    'femaleCount': 18,
    'maleCount': 14,
  };

  Map<String, dynamic> buildJson({Object? courses}) => <String, dynamic>{
    'classroom': buildClassroom(),
    'courses':
        courses ??
        <Map<String, dynamic>>[
          {'id': 'crs-1', 'branche': 'Algèbre'},
          {'id': 'crs-2', 'branche': 'Français'},
        ],
  };

  test(
    'fromJson -> toEntity mappe la classe imbriquée et les cours {id, branche}',
    () {
      final entity = CourseSummaryModel.fromJson(buildJson()).toEntity();

      expect(entity.classroom.id, 'c1');
      expect(entity.classroom.version, 3);
      expect(entity.classroom.name, '6ème A');
      expect(entity.courses, const [
        CourseRef(id: 'crs-1', label: 'Algèbre'),
        CourseRef(id: 'crs-2', label: 'Français'),
      ]);
      expect(entity.courses.first.hasId, isTrue);
    },
  );

  test('parsing tolérant : ancien format (chaînes nues) -> id vide', () {
    final entity = CourseSummaryModel.fromJson(
      buildJson(courses: <String>['Algèbre', 'Français']),
    ).toEntity();

    expect(entity.courses, const [
      CourseRef(id: '', label: 'Algèbre'),
      CourseRef(id: '', label: 'Français'),
    ]);
    // Sans id, le cours n'est pas ouvrable (tuile non interactive).
    expect(entity.courses.every((c) => c.hasId), isFalse);
  });

  test('version absent -> null (résilience backend)', () {
    final json = buildJson();
    (json['classroom'] as Map<String, dynamic>).remove('version');

    final entity = CourseSummaryModel.fromJson(json).toEntity();

    expect(entity.classroom.version, isNull);
  });

  test('liste de cours vide -> entité avec courses vide', () {
    final entity = CourseSummaryModel.fromJson(
      buildJson(courses: <dynamic>[]),
    ).toEntity();

    expect(entity.courses, isEmpty);
  });

  test('toJson encode les cours en objets {id, branche}', () {
    final model = CourseSummaryModel.fromJson(buildJson());

    final json = model.toJson();
    final courses = json['courses'] as List<dynamic>;
    expect(courses.first, {'id': 'crs-1', 'branche': 'Algèbre'});
  });

  test('classroom défensif : capacity null -> 0 (pas de crash du payload)', () {
    final json = buildJson();
    (json['classroom'] as Map<String, dynamic>)['capacity'] = null;

    final entity = CourseSummaryModel.fromJson(json).toEntity();

    expect(entity.classroom.capacity, 0);
    expect(entity.classroom.totalCount, 32);
  });

  test('cours avec id non-string -> traité comme absent (non ouvrable)', () {
    final entity = CourseSummaryModel.fromJson(
      buildJson(
        courses: <Map<String, dynamic>>[
          {'id': 123, 'branche': 'Algèbre'},
        ],
      ),
    ).toEntity();

    expect(entity.courses.single.label, 'Algèbre');
    expect(entity.courses.single.hasId, isFalse);
  });
}
