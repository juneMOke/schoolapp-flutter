import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/enrollment_summary_widgets.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';

class SummaryStep extends StatefulWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;
  final ValueChanged<int> onEditRequested;

  const SummaryStep({
    super.key,
    required this.enrollmentDetail,
    required this.onEditRequested,
  });

  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  late final StudentChargesBloc _studentChargesBloc;

  String get _studentId => widget.enrollmentDetail.studentDetail.id.trim();

  String get _levelId {
    final fromEnrollment = widget
        .enrollmentDetail
        .enrollmentDetail
        .schoolLevelId
        .trim();
    if (fromEnrollment.isNotEmpty) {
      return fromEnrollment;
    }
    return widget.enrollmentDetail.studentDetail.schoolLevel.id.trim();
  }

  bool get _canLoadCharges => _studentId.isNotEmpty && _levelId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _studentChargesBloc = getIt<StudentChargesBloc>();
    _requestCharges();
  }

  @override
  void didUpdateWidget(covariant SummaryStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      _requestCharges();
    }
  }

  @override
  void dispose() {
    _studentChargesBloc.close();
    super.dispose();
  }

  void _requestCharges() {
    if (!_canLoadCharges) return;
    _studentChargesBloc.add(
      StudentChargesRequested(studentId: _studentId, levelId: _levelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentChargesBloc>.value(
      value: _studentChargesBloc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryCompactHeader(enrollmentDetail: widget.enrollmentDetail),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryPersonalInfoSection(
            enrollmentDetail: widget.enrollmentDetail,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryAddressSection(
            enrollmentDetail: widget.enrollmentDetail,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryPreviousAcademicSection(
            enrollmentDetail: widget.enrollmentDetail,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryTargetAcademicSection(
            enrollmentDetail: widget.enrollmentDetail,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryChargesSection(
            canLoadCharges: _canLoadCharges,
            onRetry: _requestCharges,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SummaryGuardiansSection(
            parents: widget.enrollmentDetail.parentDetails,
            onEditRequested: widget.onEditRequested,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const SummaryValidationNotice(),
          const SizedBox(height: AppDimensions.spacingM),
        ],
      ),
    );
  }
}
