import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un en-tête qui trie : son libellé et la flèche du sens courant.
class StaffTableSortHeader extends StatelessWidget {
  final Widget label;
  final bool descending;
  final VoidCallback onTap;

  const StaffTableSortHeader({
    super.key,
    required this.label,
    required this.descending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      // La flèche ne se lit pas : le sens du tri se dit.
      hint: descending
          ? l10n.staffTableSortDescending
          : l10n.staffTableSortAscending,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                descending ? Icons.arrow_downward : Icons.arrow_upward,
                size: AppDimensions.detailMiniIconSize,
                color: ListingTones.inkEnteteTable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
