import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';

void main() {
  test('test fragility: message change breaks equality', () {
    // Scenario: Someone modifies NotFoundFailure default message
    // The test on line 56 expects: const Left<Failure, List>(NotFoundFailure())
    // But internally this is: const Left<Failure, List>(NotFoundFailure('Resource not found'))

    final actualLeft = const Left<Failure, dynamic>(NotFoundFailure());
    final expectedLeft = const Left<Failure, dynamic>(NotFoundFailure());

    // This works because both use the same default message
    expect(actualLeft, expectedLeft);

    // But if someone changes the default message in failures.dart:
    // const NotFoundFailure([super.message = 'Not found']); // Changed!
    // Then this test would fail silently with code recompile
  });
}
