import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summaries_widget.dart';

class FirstRegistrationPage extends StatelessWidget {
  const FirstRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnrollmentSummariesWidget(
        status: 'COMPLETED',
        showStatusBadge: false,
        intentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
        ),
        action: ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigation vers création d'inscription
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Nouvelle inscription'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
