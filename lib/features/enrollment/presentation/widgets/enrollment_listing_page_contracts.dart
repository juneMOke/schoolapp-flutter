import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';

typedef EnrollmentBootstrapBuilder =
    Widget Function(
      BuildContext context,
      Widget Function(BuildContext context, EnrollmentScreenContext ctx)
      onReady,
    );

typedef EnrollmentSearchSectionBuilder =
    Widget Function(
      BuildContext context,
      EnrollmentScreenContext ctx,
      EnrollmentSearchDispatcher dispatch,
    );

typedef EnrollmentSearchDispatcher =
    void Function(EnrollmentSearchCommand command);

typedef EnrollmentSearchCommandHandler =
    void Function(
      BuildContext context,
      EnrollmentSearchCommand command,
      EnrollmentScreenContext screenCtx,
    );

typedef EnrollmentDetailIntentFactory =
    EnrollmentDetailIntent Function(EnrollmentSummary summary);

typedef EnrollmentEmptyStateBuilder =
    Widget Function(BuildContext context, EnrollmentState state);

typedef EnrollmentResultsSummaryBuilder =
    Widget Function(
      BuildContext context,
      EnrollmentState state,
      EnrollmentScreenContext screenCtx,
    );

class EnrollmentScreenContext {
  final String schoolId;
  final String academicYearId;
  final bool isLoading;
  final Future<void> Function()? onRefreshRequested;
  final EnrollmentListingViewMode preferredViewMode;
  final VoidCallback? onSortToggled;
  final ValueChanged<EnrollmentListingViewMode>? onViewModeChanged;
  final VoidCallback? onResetSearchRequested;
  final VoidCallback? onCreateEnrollmentRequested;
  final VoidCallback? onReconnectRequested;
  final VoidCallback? onContactAdminRequested;

  const EnrollmentScreenContext({
    required this.schoolId,
    required this.academicYearId,
    required this.isLoading,
    this.onRefreshRequested,
    this.preferredViewMode = EnrollmentListingViewMode.auto,
    this.onSortToggled,
    this.onViewModeChanged,
    this.onResetSearchRequested,
    this.onCreateEnrollmentRequested,
    this.onReconnectRequested,
    this.onContactAdminRequested,
  });
}

sealed class EnrollmentSearchCommand {
  const EnrollmentSearchCommand();
}

class AcademicInfoSearchCommand extends EnrollmentSearchCommand {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const AcademicInfoSearchCommand({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

class StandardSearchCommand extends EnrollmentSearchCommand {
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? dateOfBirth;
  final String status;

  const StandardSearchCommand({
    this.firstName,
    this.lastName,
    this.surname,
    this.dateOfBirth,
    required this.status,
  });
}
