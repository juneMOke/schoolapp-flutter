import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentDetailInfoBar extends StatelessWidget {
  final String enrollmentCode;
  final EnrollmentStatus status;

  const EnrollmentDetailInfoBar({
    super.key,
    required this.enrollmentCode,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.14),
            const Color(0xFF10B981).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enrollmentCode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.preRegistered:
        return 'PRE_REGISTERED';
      case EnrollmentStatus.inProgress:
        return 'IN_PROGRESS';
      case EnrollmentStatus.adminCompleted:
        return 'ADMIN_COMPLETED';
      case EnrollmentStatus.financialCompleted:
        return 'FINANCIAL_COMPLETED';
      case EnrollmentStatus.completed:
        return 'COMPLETED';
      case EnrollmentStatus.cancelled:
        return 'CANCELLED';
      case EnrollmentStatus.validated:
        return 'VALIDATED';
      case EnrollmentStatus.rejected:
        return 'REJECTED';
      case EnrollmentStatus.pending:
        return 'PENDING';
    }
  }
}
