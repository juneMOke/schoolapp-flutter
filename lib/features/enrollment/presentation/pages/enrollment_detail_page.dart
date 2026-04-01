import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_app_bar_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';

class EnrollmentDetailPage extends StatelessWidget {
  final String enrollmentId;

  const EnrollmentDetailPage({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GetIt.instance<EnrollmentBloc>()
            ..add(EnrollmentDetailRequested(enrollmentId: enrollmentId)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 18,
          title: EnrollmentDetailAppBarTitle(enrollmentId: enrollmentId),
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
                  onRetry: () {
                    context.read<EnrollmentBloc>().add(
                      EnrollmentDetailRequested(enrollmentId: enrollmentId),
                    );
                  },
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
      ),
    );
  }
}
