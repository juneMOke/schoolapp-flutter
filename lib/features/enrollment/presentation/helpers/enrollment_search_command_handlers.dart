import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentSearchCommandHandlers {
  const EnrollmentSearchCommandHandlers._();

  /// Traduit une commande de recherche de l'UI en événement du listing LOCAL
  /// (`EnrollmentLocalListBloc`). Le raffinement (nom/DOB) est ensuite appliqué
  /// côté client par le bloc ; le statut porté par la commande scope la base.
  static void dispatchThroughLocalListBloc(
    BuildContext context,
    EnrollmentSearchCommand command,
    EnrollmentScreenContext screenCtx,
  ) {
    final bloc = context.read<EnrollmentLocalListBloc>();

    switch (command) {
      case AcademicInfoSearchCommand():
        bloc.add(
          LocalListByAcademicInfoRequested(
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

        final academicYearId = screenCtx.academicYearId;
        // Filtre de type propre à la page (ex. Pré-inscriptions → PRE_ENROLLMENT) :
        // porté sur TOUS les chemins de recherche pour ne jamais laisser
        // réapparaître un dossier de réinscription (même statut PRE_REGISTERED).
        final enrollmentType = screenCtx.enrollmentType;

        if (hasAllNames && hasDate) {
          bloc.add(
            LocalListByStudentNamesAndDateOfBirthRequested(
              firstName: firstName,
              lastName: lastName,
              surname: surname,
              dateOfBirth: dateOfBirth,
              status: command.status,
              academicYearId: academicYearId,
              enrollmentType: enrollmentType,
              page: 0,
            ),
          );
          return;
        }

        if (hasAllNames) {
          bloc.add(
            LocalListByStudentNameRequested(
              firstName: firstName,
              lastName: lastName,
              surname: surname,
              status: command.status,
              academicYearId: academicYearId,
              enrollmentType: enrollmentType,
              page: 0,
            ),
          );
          return;
        }

        if (hasDate) {
          bloc.add(
            LocalListByDateOfBirthRequested(
              dateOfBirth: dateOfBirth,
              status: command.status,
              academicYearId: academicYearId,
              enrollmentType: enrollmentType,
              page: 0,
            ),
          );
          return;
        }

        bloc.add(
          LocalListByStatusRequested(
            status: command.status,
            academicYearId: academicYearId,
            enrollmentType: enrollmentType,
            page: 0,
          ),
        );
    }
  }
}
