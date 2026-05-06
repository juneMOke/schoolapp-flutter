import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_policy.dart';

void main() {
  group('ClassesListPolicyResolver', () {
    test('classesList intent resolves default policy', () {
      final policy = ClassesListPolicyResolver.fromIntent(
        const ClassesListIntent.classesList(),
      );

      expect(policy, isA<DefaultClassesListPolicy>());
    });

    test('disciplinesList intent resolves disciplines policy', () {
      final policy = ClassesListPolicyResolver.fromIntent(
        const ClassesListIntent.disciplinesList(),
      );

      expect(policy, isA<DisciplinesClassesListPolicy>());
    });
  });
}
