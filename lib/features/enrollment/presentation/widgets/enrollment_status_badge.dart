import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/enrollment_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const EnrollmentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(l10n),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    return switch (status) {
      EnrollmentStatus.preRegistered => EnrollmentTheme.pendingColor,
      EnrollmentStatus.validated => EnrollmentTheme.validatedColor,
      EnrollmentStatus.rejected => EnrollmentTheme.rejectedColor,
      // TODO: Handle this case.
      EnrollmentStatus.inProgress => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.adminCompleted => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.financialCompleted => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.completed => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.cancelled => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.pending => throw UnimplementedError(),
    };
  }

  String _getStatusText(AppLocalizations l10n) {
    return switch (status) {
      EnrollmentStatus.preRegistered => l10n.statusPending,
      EnrollmentStatus.validated => l10n.statusValidated,
      EnrollmentStatus.rejected => l10n.statusRejected,
      // TODO: Handle this case.
      EnrollmentStatus.inProgress => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.adminCompleted => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.financialCompleted => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.completed => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.cancelled => throw UnimplementedError(),
      // TODO: Handle this case.
      EnrollmentStatus.pending => throw UnimplementedError(),
    };
  }
}