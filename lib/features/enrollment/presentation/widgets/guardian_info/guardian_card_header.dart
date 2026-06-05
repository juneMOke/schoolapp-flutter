import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianCardHeader extends StatelessWidget {
  final ParentSummary parent;
  final bool isPrimary;
  final bool isExpanded;
  final bool isComplete;
  final VoidCallback? onToggle;

  const GuardianCardHeader({
    super.key,
    required this.parent,
    required this.isPrimary,
    required this.isExpanded,
    this.isComplete = true,
    this.onToggle,
  });

  String _relationshipLabel(AppLocalizations l10n, RelationshipType type) {
    return switch (type) {
      RelationshipType.father => l10n.relationshipFather,
      RelationshipType.mother => l10n.relationshipMother,
      RelationshipType.guardian => l10n.relationshipGuardian,
      RelationshipType.uncle => l10n.relationshipUncle,
      RelationshipType.aunt => l10n.relationshipAunt,
      RelationshipType.grandparent => l10n.relationshipGrandparent,
      RelationshipType.other => l10n.relationshipOther,
    };
  }

  Widget _buildAvatar() {
    final initials =
        '${parent.firstName.isNotEmpty ? parent.firstName[0] : ''}${parent.lastName.isNotEmpty ? parent.lastName[0] : ''}'
            .toUpperCase();
    final hasInitials = initials.trim().isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasInitials ? AppColors.bleuArdoise : AppColors.surfaceAlt,
        border: Border.all(
          color: hasInitials ? AppColors.bleuArdoise : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: hasInitials
          ? Text(
              initials,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.blancCasse,
                fontWeight: FontWeight.w700,
              ),
            )
          : const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
    );
  }

  Widget _buildPrimaryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise.withValues(alpha: 0.10),
        borderRadius: AppRadius.brSm,
        border: Border.all(
          color: AppColors.bleuArdoise.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 12,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.bleuArdoise,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = '${parent.firstName} ${parent.lastName}'.trim();

    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fullName.isEmpty ? '—' : fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (isPrimary) ...[
                    const SizedBox(width: 6),
                    _buildPrimaryBadge(l10n.guardianPrincipalBadge),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${_relationshipLabel(l10n, parent.relationshipType)} • ${parent.phoneNumber.trim().isEmpty ? '—' : parent.phoneNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        if (!isComplete) ...[
          Tooltip(
            message: l10n.guardianIncompleteHint,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            tooltip: l10n.guardianToggleCard,
            onPressed: onToggle,
            icon: Icon(
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            splashRadius: 18,
          ),
        ),
      ],
    );
  }
}
