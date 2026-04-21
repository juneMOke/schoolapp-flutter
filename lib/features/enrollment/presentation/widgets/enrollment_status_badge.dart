import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/extensions/enrollment_status_color_extension.dart';
import 'package:school_app_flutter/features/enrollment/presentation/extensions/enrollment_status_l10n_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const EnrollmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = status.badgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.localizedLabel(l10n),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
