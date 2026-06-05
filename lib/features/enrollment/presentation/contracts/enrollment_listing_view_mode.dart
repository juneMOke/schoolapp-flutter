enum EnrollmentListingViewMode { auto, table, grid }

extension EnrollmentListingViewModeX on EnrollmentListingViewMode {
  bool get isTable => this == EnrollmentListingViewMode.table;

  bool get isGrid => this == EnrollmentListingViewMode.grid;
}
