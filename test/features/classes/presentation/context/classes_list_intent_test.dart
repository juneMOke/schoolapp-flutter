import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_origin.dart';

void main() {
  group('ClassesListIntent', () {
    test('classesList constructor targets classes list origin', () {
      const intent = ClassesListIntent.classesList();

      expect(intent.origin, ClassesListOrigin.classesList);
    });

    test('disciplinesList constructor targets disciplines list origin', () {
      const intent = ClassesListIntent.disciplinesList();

      expect(intent.origin, ClassesListOrigin.disciplinesList);
    });
  });
}
