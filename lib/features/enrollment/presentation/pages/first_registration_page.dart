import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
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
      floatingActionButton: EteeloFab(
        label: l10n.firstRegistrationNewEnrollmentAction,
        icon: Icons.add,
        onPressed: () {
          context.go(
            '${EnrollmentConstants.enrollmentDetailRoute}/new',
            extra: const EnrollmentDetailIntent.newFirstRegistration(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: EnrollmentSummariesWidget(
        status: 'IN_PROGRESS',
        showStatusBadge: false,
        showStatusFilter: true,
        contentPadding:
            EnrollmentPageLayout.firstRegistrationContentPaddingWithFab,
        loadingPadding: EnrollmentPageLayout.loadingPadding,
        sectionSpacing: EnrollmentPageLayout.sectionSpacing,
        intentFactory: (summary) => EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: summary.enrollmentId,
          status: summary.status,
        ),
      ),
    );
  }
}
