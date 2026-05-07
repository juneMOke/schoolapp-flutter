import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couples each API status value with its localized label.
class _StatusOption {
  const _StatusOption(this.value, this.label);

  final String value;
  final String label;
}

class _StatusVisual {
  const _StatusVisual({required this.icon, required this.base});

  final IconData icon;
  final Color base;
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

    final borderRadius = BorderRadius.circular(AppDimensions.spacingS + 2);
    const borderSide = BorderSide(color: AppColors.border);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedStatus,
        borderRadius: borderRadius,
        dropdownColor: AppColors.surface,
        menuMaxHeight: 320,
        decoration: InputDecoration(
          labelText: l10n.enrollmentStatusFilterLabel,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.tune_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          isDense: false,
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: borderSide,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(
              color: AppColors.bleuArdoise,
              width: 1.4,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS + 2,
            vertical: AppDimensions.spacingS + 2,
          ),
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        isExpanded: true,
        itemHeight: null,
        selectedItemBuilder: (context) => options
            .map((o) => _buildSelectedStatusItem(o))
            .toList(),
        items: options
            .map(
              (o) => DropdownMenuItem<String>(
                value: o.value,
                child: _buildStatusItem(
                  o,
                  isSelected: o.value == selectedStatus,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  Widget _buildStatusItem(
    _StatusOption option,
    {
    required bool isSelected,
  }) {
    final visual = _visualForStatus(option.value);
    final tileBackground = isSelected
        ? _blendWithSurface(visual.base, 0.88)
        : _blendWithSurface(visual.base, 0.94);
    final badgeBackground = _blendWithSurface(visual.base, 0.84);
    final tileBorder = visual.base.withValues(alpha: isSelected ? 0.35 : 0.18);
    final textColor = isSelected ? visual.base : AppColors.textPrimary;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.outCurve,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXS + 2,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.spacingM + 10,
            height: AppDimensions.spacingM + 10,
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              border: Border.all(color: visual.base.withValues(alpha: 0.24)),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 14, color: visual.base),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          AnimatedOpacity(
            duration: AppMotion.fast,
            curve: AppMotion.outCurve,
            opacity: isSelected ? 1 : 0,
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: visual.base,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedStatusItem(
    _StatusOption option,
  ) {
    final visual = _visualForStatus(option.value);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: AppDimensions.spacingM + 8,
            height: AppDimensions.spacingM + 8,
            decoration: BoxDecoration(
              color: _blendWithSurface(visual.base, 0.86),
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              border: Border.all(color: visual.base.withValues(alpha: 0.26)),
            ),
            alignment: Alignment.center,
            child: Icon(visual.icon, size: 13, color: visual.base),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: visual.base,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _blendWithSurface(Color color, double amount) =>
      Color.lerp(color, AppColors.surface, amount) ?? color;

  _StatusVisual _visualForStatus(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return const _StatusVisual(
          icon: Icons.autorenew_rounded,
          base: AppColors.warning,
        );
      case 'ADMIN_COMPLETED':
        return const _StatusVisual(
          icon: Icons.assignment_turned_in_rounded,
          base: AppColors.bleuArdoise,
        );
      case 'FINANCIAL_COMPLETED':
        return const _StatusVisual(
          icon: Icons.account_balance_wallet_rounded,
          base: AppColors.info,
        );
      case 'COMPLETED':
        return const _StatusVisual(
          icon: Icons.task_alt_rounded,
          base: AppColors.success,
        );
      case 'VALIDATED':
        return const _StatusVisual(
          icon: Icons.verified_rounded,
          base: AppColors.success,
        );
      case 'REJECTED':
        return const _StatusVisual(
          icon: Icons.gpp_bad_rounded,
          base: AppColors.terreCuite,
        );
      case 'CANCELLED':
        return const _StatusVisual(
          icon: Icons.cancel_rounded,
          base: AppColors.error,
        );
      default:
        return const _StatusVisual(
          icon: Icons.label_rounded,
          base: AppColors.textSecondary,
        );
    }
  }
}
