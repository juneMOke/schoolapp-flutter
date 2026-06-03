import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couples each API status value with its localized label.
class _StatusOption {
  const _StatusOption(this.value, this.label);

  final String value;
  final String label;
}

/// Dropdown displayed in the search form when [showStatusFilter] is true
/// (i.e. on the first-registration page). Shows all statuses relevant to
/// first-registration workflows, defaulting to IN_PROGRESS.
class SearchFormStatusDropdown extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const SearchFormStatusDropdown({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <_StatusOption>[
      _StatusOption('IN_PROGRESS', l10n.enrollmentStatusInProgress),
      _StatusOption('ADMIN_COMPLETED', l10n.enrollmentStatusAdminCompleted),
      _StatusOption(
        'FINANCIAL_COMPLETED',
        l10n.enrollmentStatusFinancialCompleted,
      ),
      _StatusOption('COMPLETED', l10n.enrollmentStatusCompleted),
      _StatusOption('VALIDATED', l10n.enrollmentStatusValidated),
      _StatusOption('REJECTED', l10n.enrollmentStatusRejected),
      _StatusOption('CANCELLED', l10n.enrollmentStatusCancelled),
    ];

    final selectedValue = options.any((o) => o.value == selectedStatus)
        ? selectedStatus
        : options.first.value;

    final selectItems = options
        .map(
          (option) => EteeloSelectItem<String>(
            value: option.value,
            label: option.label,
          ),
        )
        .toList(growable: false);

    return EteeloSelectInput<String>(
      label: l10n.enrollmentStatusFilterLabel,
      placeholder: l10n.selectPlaceholderChoose,
      value: selectedValue,
      items: selectItems,
      menuMaxHeight: 320,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      itemBuilder: (context, item, isSelected) {
        final option = _StatusOption(item.value, item.label);
        return _buildStatusItem(option, l10n: l10n, isSelected: isSelected);
      },
      selectedItemBuilder: (context, item) {
        final option = _StatusOption(item.value, item.label);
        return _buildSelectedStatusItem(option, l10n);
      },
    );
  }

  Widget _buildStatusItem(
    _StatusOption option, {
    required AppLocalizations l10n,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXS + 2,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.bleuArdoise.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(
          color: isSelected
              ? AppColors.bleuArdoise.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEnrollmentStatusBadge(
              statusValue: option.value,
              label: option.label,
              l10n: l10n,
              size: StatusBadgeSize.small,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          AnimatedOpacity(
            duration: AppMotion.fast,
            curve: AppMotion.outCurve,
            opacity: isSelected ? 1 : 0,
            child: const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.bleuArdoise,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedStatusItem(_StatusOption option, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _buildEnrollmentStatusBadge(
        statusValue: option.value,
        label: option.label,
        l10n: l10n,
        size: StatusBadgeSize.medium,
      ),
    );
  }

  StatusBadge _buildEnrollmentStatusBadge({
    required String statusValue,
    required String label,
    required AppLocalizations l10n,
    required StatusBadgeSize size,
  }) {
    final status = EnrollmentStatus.fromString(statusValue);
    return switch (status) {
      EnrollmentStatus.preRegistered => StatusBadge.enrollmentPreRegistered(
        label: label,
        size: size,
      ),
      EnrollmentStatus.inProgress => StatusBadge.enrollmentInProgress(
        label: label,
        size: size,
      ),
      EnrollmentStatus.adminCompleted => StatusBadge.enrollmentAdminCompleted(
        label: label,
        size: size,
      ),
      EnrollmentStatus.financialCompleted =>
        StatusBadge.enrollmentFinancialCompleted(label: label, size: size),
      EnrollmentStatus.completed => StatusBadge.enrollmentCompleted(
        label: label,
        size: size,
      ),
      EnrollmentStatus.cancelled => StatusBadge.enrollmentCancelled(
        label: label,
        size: size,
      ),
      EnrollmentStatus.validated => StatusBadge.enrollmentValidated(
        label: label,
        size: size,
      ),
      EnrollmentStatus.rejected => StatusBadge.enrollmentRejected(
        label: label,
        size: size,
      ),
      EnrollmentStatus.pending => StatusBadge.enrollmentPending(
        label: l10n.statusPending,
        size: size,
      ),
    };
  }
}
