import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_my_courses_usecase.dart';

class MockCourseRepository extends Mock implements CourseRepository {}

const tCourse = CourseSummary(
  classroom: ClassroomSummary(
    id: 'c1',
    schoolLevelId: 'lvl-1',
    name: '6ème A',
    capacity: 40,
    totalCount: 32,
    femaleCount: 18,
    maleCount: 14,
  ),
  courses: [
    CourseRef(id: 'crs-1', label: 'Algèbre'),
    CourseRef(id: 'crs-2', label: 'Français'),
  ],
);

void main() {
  late MockCourseRepository mockRepository;
  late GetMyCoursesUseCase useCase;

  setUp(() {
    mockRepository = MockCourseRepository();
    useCase = GetMyCoursesUseCase(mockRepository);
  });

  test('délègue au repository et renvoie Right en cas de succès', () async {
    when(
      () => mockRepository.getMyCourses(),
    ).thenAnswer((_) async => const Right([tCourse]));

    final result = await useCase();

    result.fold(
      (_) => fail('Right attendu'),
      (courses) => expect(courses, const [tCourse]),
    );
    verify(() => mockRepository.getMyCourses()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propage la Failure du repository', () async {
    when(
      () => mockRepository.getMyCourses(),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase();

    expect(result, const Left<Failure, List<CourseSummary>>(NotFoundFailure()));
  });
}
