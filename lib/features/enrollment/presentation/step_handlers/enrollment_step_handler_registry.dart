import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/address_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/guardian_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/personal_info_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/previous_academic_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/student_charges_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/summary_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/target_academic_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

class EnrollmentStepHandlerDependencies {
  final EnrollmentStepSubmitController personalInfoController;
  final EnrollmentStepSubmitController addressController;
  final EnrollmentStepSubmitController academicInfoController;
  final EnrollmentStepSubmitController academicTargetInfoController;
  final EnrollmentStepSubmitController studentChargesController;
  final EnrollmentStepSubmitController guardianInfoController;

  const EnrollmentStepHandlerDependencies({
    required this.personalInfoController,
    required this.addressController,
    required this.academicInfoController,
    required this.academicTargetInfoController,
    required this.studentChargesController,
    required this.guardianInfoController,
  });
}

class EnrollmentStepFlowPlan {
  final List<EnrollmentStepHandler> handlers;
  final Map<int, StepFormState> initialStepStates;

  const EnrollmentStepFlowPlan({
    required this.handlers,
    required this.initialStepStates,
  });

  int get totalSteps => handlers.length;
}

class EnrollmentStepHandlerRegistry {
  const EnrollmentStepHandlerRegistry._();

  static EnrollmentStepFlowPlan buildPlan({
    required EnrollmentStepHandlerDependencies dependencies,
    required EnrollmentDetail detail,
  }) {
    return buildPlanFromHandlers(
      handlers: create(dependencies),
      detail: detail,
    );
  }

  static EnrollmentStepFlowPlan buildPlanFromHandlers({
    required List<EnrollmentStepHandler> handlers,
    required EnrollmentDetail detail,
  }) {
    final initialStepStates = <int, StepFormState>{
      for (final handler in handlers)
        handler.order: handler.initialState(
          HandlerInitialStateContext(detail: detail),
        ),
    };

    return EnrollmentStepFlowPlan(
      handlers: handlers,
      initialStepStates: Map<int, StepFormState>.unmodifiable(
        initialStepStates,
      ),
    );
  }

  static List<EnrollmentStepHandler> create(
    EnrollmentStepHandlerDependencies dependencies,
  ) {
    final handlers = <EnrollmentStepHandler>[
      PersonalInfoStepHandler(controller: dependencies.personalInfoController),
      AddressStepHandler(controller: dependencies.addressController),
      PreviousAcademicStepHandler(
        controller: dependencies.academicInfoController,
      ),
      TargetAcademicStepHandler(
        controller: dependencies.academicTargetInfoController,
      ),
      StudentChargesStepHandler(
        controller: dependencies.studentChargesController,
      ),
      GuardianStepHandler(controller: dependencies.guardianInfoController),
      SummaryStepHandler(),
    ]..sort((a, b) => a.order.compareTo(b.order));

    return List<EnrollmentStepHandler>.unmodifiable(handlers);
  }
}
