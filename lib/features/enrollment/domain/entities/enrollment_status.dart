enum EnrollmentStatus {
  pending,
  inProgress,
  validated,
  rejected;

  static EnrollmentStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return EnrollmentStatus.inProgress;
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
