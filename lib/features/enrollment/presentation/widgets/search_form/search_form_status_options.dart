import 'package:school_app_flutter/l10n/app_localizations.dart';

class SearchFormStatusOption {
  final String value;
  final String label;

  const SearchFormStatusOption({required this.value, required this.label});
}

List<SearchFormStatusOption> buildEnrollmentStatusOptions(
  AppLocalizations l10n,
) => [
  SearchFormStatusOption(
    value: 'IN_PROGRESS',
    label: l10n.enrollmentStatusInProgress,
  ),
  SearchFormStatusOption(
    value: 'COMPLETED',
    label: l10n.enrollmentStatusCompleted,
  ),
];
