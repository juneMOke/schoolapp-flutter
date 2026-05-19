import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler_registry.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';

void main() {
  group('EnrollmentStepHandlerRegistry', () {
    test('create retourne des handlers ordonnes et uniques par step', () {
      final dependencies = _buildDependencies();

      final handlers = EnrollmentStepHandlerRegistry.create(dependencies);

      expect(handlers, isNotEmpty);
      for (var i = 0; i < handlers.length; i++) {
        expect(handlers[i].order, i);
      }
      expect(
        handlers.map((handler) => handler.step).toSet().length,
        handlers.length,
      );
    });

    test('buildPlan retourne un plan coherent handlers/totalSteps/states', () {
      final dependencies = _buildDependencies();
      final detail = EnrollmentDetail.empty();

      final plan = EnrollmentStepHandlerRegistry.buildPlan(
        dependencies: dependencies,
        detail: detail,
      );

      expect(plan.handlers, isNotEmpty);
      expect(plan.totalSteps, plan.handlers.length);
      expect(plan.initialStepStates.length, plan.handlers.length);

      for (var i = 0; i < plan.handlers.length; i++) {
        final handler = plan.handlers[i];
        expect(handler.order, i);
        expect(
          plan.initialStepStates[handler.order],
          handler.initialState(HandlerInitialStateContext(detail: detail)),
        );
      }
    });

    test('buildPlanFromHandlers preserve totalSteps et états initiaux', () {
      final dependencies = _buildDependencies();
      final detail = EnrollmentDetail.empty();

      final handlers = EnrollmentStepHandlerRegistry.create(dependencies);
      final plan = EnrollmentStepHandlerRegistry.buildPlanFromHandlers(
        handlers: handlers,
        detail: detail,
      );

      expect(plan.totalSteps, handlers.length);
      expect(plan.initialStepStates.length, handlers.length);

      for (final handler in handlers) {
        expect(
          plan.initialStepStates[handler.order],
          handler.initialState(HandlerInitialStateContext(detail: detail)),
        );
      }
    });

    test('createInitialStepStates couvre tous les handlers de la registry', () {
      final dependencies = _buildDependencies();
      final detail = EnrollmentDetail.empty();

      final plan = EnrollmentStepHandlerRegistry.buildPlan(
        dependencies: dependencies,
        detail: detail,
      );
      final initialStates = plan.initialStepStates;
      final handlers = plan.handlers;

      expect(initialStates.length, handlers.length);

      for (final handler in handlers) {
        final expected = handler.initialState(
          HandlerInitialStateContext(detail: detail),
        );
        expect(initialStates[handler.order], expected);
      }
    });
  });
}

EnrollmentStepHandlerDependencies _buildDependencies() {
  return EnrollmentStepHandlerDependencies(
    personalInfoController: EnrollmentStepSubmitController(),
    addressController: EnrollmentStepSubmitController(),
    academicInfoController: EnrollmentStepSubmitController(),
    academicTargetInfoController: EnrollmentStepSubmitController(),
    studentChargesController: EnrollmentStepSubmitController(),
    guardianInfoController: EnrollmentStepSubmitController(),
  );
}
