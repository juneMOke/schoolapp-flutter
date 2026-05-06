import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summaries_widget.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FirstRegistrationPage extends StatelessWidget {
  const FirstRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: false,
      child: EnrollmentSummariesWidget(
        status: 'IN_PROGRESS',
        showStatusBadge: false,
        showStatusFilter: true,
        contentPadding: EnrollmentPageLayout.contentPadding,
        loadingPadding: EnrollmentPageLayout.loadingPadding,
        sectionSpacing: EnrollmentPageLayout.sectionSpacing,
        intentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
          status: summary.status,
        ),
        action: ElevatedButton.icon(
          onPressed: () {
            context.go(
              '${EnrollmentConstants.enrollmentDetailRoute}/new',
              extra: const EnrollmentDetailIntent.newFirstRegistration(),
            );
          },
          icon: const Icon(Icons.add, size: 16),
          label: Text(l10n.firstRegistrationNewEnrollmentAction),
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
