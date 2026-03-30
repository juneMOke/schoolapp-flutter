enum EnrollmentStatus {
  preRegistered,
  inProgress,
  adminCompleted,
  financialCompleted,
  completed,
  cancelled,
  validated,
  rejected,
  pending;

  @override
  String toString() => name.toLowerCase();

  static EnrollmentStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRE_REGISTERED':
        return EnrollmentStatus.preRegistered;
      case 'IN_PROGRESS':
        return EnrollmentStatus.inProgress;
      case 'ADMIN_COMPLETED':
        return EnrollmentStatus.adminCompleted;
      case 'FINANCIAL_COMPLETED':
        return EnrollmentStatus.financialCompleted;
      case 'COMPLETED':
        return EnrollmentStatus.completed;
      case 'CANCELLED':
        return EnrollmentStatus.cancelled;
      case 'VALIDATED':
        return EnrollmentStatus.validated;
      case 'REJECTED':
        return EnrollmentStatus.rejected;
      case 'PENDING':
      default:
        return EnrollmentStatus.pending;
    }
  }
}
