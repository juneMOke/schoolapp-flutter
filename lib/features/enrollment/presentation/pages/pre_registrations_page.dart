import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summaries_widget.dart';

class PreRegistrationsPage extends StatelessWidget {
  const PreRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnrollmentSummariesWidget(
        status: 'PRE_REGISTERED',
        intentFactory: (summary) => EnrollmentDetailIntent.preRegistration(
          enrollmentId: summary.enrollmentId,
        ),
      ),
    );
  }
}
