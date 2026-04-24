import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_item.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianInfoStepBody extends StatelessWidget {
  final List<ParentSummary> parentDetails;
  final ParentItemStateChanged onItemStateChanged;
  final ParentItemValueChanged onItemValueChanged;
  final VoidCallback? onAddParent;
  final ValueChanged<String>? onRemoveParent;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final VoidCallback onSave;
  final bool isEditable;

  const GuardianInfoStepBody({
    super.key,
    required this.parentDetails,
    required this.onItemStateChanged,
    required this.onItemValueChanged,
    this.onAddParent,
    this.onRemoveParent,
    this.isLoading = false,
    this.canSave = false,
    this.showInlineSaveButton = true,
    required this.onSave,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAddParent = isEditable && !isLoading;

    final addButton = FilledButton.tonalIcon(
      onPressed: canAddParent ? onAddParent : null,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: Text(l10n.guardianAddAction),
      style: FilledButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

    return AbsorbPointer(
      absorbing: isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.guardianInformation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                addButton,
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Padding(
                    key: const ValueKey<String>('guardian-loading-bar'),
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(minHeight: 4),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          if (parentDetails.isEmpty)
            const GuardianEmptyState()
          else
            ...parentDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final parent = entry.value;
              return Padding(
                key: ValueKey<String>('parent-item-${parent.id}'),
                padding: EdgeInsets.only(
                  bottom: index < parentDetails.length - 1 ? 16 : 0,
                ),
                child: ParentItem(
                  parent: parent,
                  isPrimary: index == 0,
                  number: index + 1,
                  onFormStateChanged: onItemStateChanged,
                  onValueChanged: onItemValueChanged,
                  onRemoveRequested: isEditable
                      ? () => onRemoveParent?.call(parent.id)
                      : null,
                  isEditable: isEditable,
                ),
              );
            }),
          if (showInlineSaveButton)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton.icon(
                onPressed: canSave && !isLoading ? onSave : null,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.guardianSaveAction),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
