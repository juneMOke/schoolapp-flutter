import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_app_bar_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final String enrollmentId;

  const EnrollmentDetailPage({super.key, required this.enrollmentId});

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  @override
  void initState() {
    super.initState();
    _requestDetail();
  }

  @override
  void didUpdateWidget(covariant EnrollmentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentId != widget.enrollmentId) {
      _requestDetail();
    }
  }

  void _requestDetail() {
    context.read<EnrollmentBloc>().add(
      EnrollmentDetailRequested(enrollmentId: widget.enrollmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: EnrollmentDetailAppBarTitle(enrollmentId: widget.enrollmentId),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          if (state.detailStatus == EnrollmentLoadStatus.loading) {
            return const EnrollmentDetailPageStateShell(
              child: EnrollmentDetailLoadingTemplate(),
            );
          }

          if (state.detailStatus == EnrollmentLoadStatus.failure) {
            return EnrollmentDetailPageStateShell(
              child: EnrollmentDetailErrorTemplate(
                message:
                    state.errorMessage ??
                    'Erreur lors du chargement des détails.',
                onRetry: _requestDetail,
              ),
            );
          }

          if (state.detail == null) {
            return const EnrollmentDetailPageStateShell(
              child: EnrollmentDetailEmptyTemplate(),
            );
          }

          final enrollment = state.detail!.enrollmentDetail;

          return EnrollmentDetailContentShell(
            infoBar: EnrollmentDetailInfoBar(
              enrollmentCode: enrollment.enrollmentCode,
              status: enrollment.status,
            ),
            child: EnrollmentStepper(enrollmentDetail: state.detail!),
          );
        },
      ),
    );
  }
}
