import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentSearchCommandHandlers {
  const EnrollmentSearchCommandHandlers._();

  static void dispatchThroughEnrollmentBloc(
    BuildContext context,
    EnrollmentSearchCommand command,
    EnrollmentScreenContext screenCtx,
  ) {
    final bloc = context.read<EnrollmentBloc>();

    switch (command) {
      case AcademicInfoSearchCommand():
        bloc.add(
          EnrollmentSummariesByAcademicInfoRequested(
            firstName: command.firstName,
            lastName: command.lastName,
            surname: command.surname,
            schoolLevelGroupId: command.schoolLevelGroupId,
            schoolLevelId: command.schoolLevelId,
            page: 0,
          ),
        );
      case StandardSearchCommand():
        final firstName = command.firstName?.trim() ?? '';
        final lastName = command.lastName?.trim() ?? '';
        final surname = command.surname?.trim() ?? '';
        final dateOfBirth = command.dateOfBirth?.trim() ?? '';
        final hasAllNames =
            firstName.isNotEmpty && lastName.isNotEmpty && surname.isNotEmpty;
        final hasDate = dateOfBirth.isNotEmpty;

        if (hasAllNames && hasDate) {
          bloc.add(
            EnrollmentSummariesByStudentNamesAndDateOfBirthRequested(
              firstName: firstName,
              lastName: lastName,
              surname: surname,
              dateOfBirth: dateOfBirth,
              status: command.status,
              academicYearId: screenCtx.academicYearId,
              page: 0,
            ),
          );
          return;
        }

        if (hasAllNames) {
          bloc.add(
            EnrollmentSummariesByStudentNameRequested(
              firstName: firstName,
              lastName: lastName,
              surname: surname,
              status: command.status,
              academicYearId: screenCtx.academicYearId,
              page: 0,
            ),
          );
          return;
        }

        if (hasDate) {
          bloc.add(
            EnrollmentSummariesByDateOfBirthRequested(
              dateOfBirth: dateOfBirth,
              status: command.status,
              academicYearId: screenCtx.academicYearId,
              page: 0,
            ),
          );
          return;
        }

        bloc.add(
          EnrollmentSummariesRequested(
            status: command.status,
            academicYearId: screenCtx.academicYearId,
            page: 0,
          ),
        );
    }
  }
}
