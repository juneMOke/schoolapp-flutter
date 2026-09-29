import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les matières d'un enseignant : un champ, et des puces supprimables.
/// Déclaratif — l'affectation réelle reste celle des cours.
class StaffBranchesField extends StatefulWidget {
  final List<String> branches;
  final bool readOnly;
  final ValueChanged<List<String>> onChanged;

  const StaffBranchesField({
    super.key,
    required this.branches,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  State<StaffBranchesField> createState() => _StaffBranchesFieldState();
}

class _StaffBranchesFieldState extends State<StaffBranchesField> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    final exists = widget.branches.any(
      (b) => b.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.branches, value]);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.staffFieldBranches, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        if (widget.branches.isEmpty && widget.readOnly)
          Text(
            l10n.staffValueNotSet,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final branch in widget.branches)
              InputChip(
                label: Text(branch),
                onDeleted: widget.readOnly
                    ? null
                    : () => widget.onChanged([
                        for (final b in widget.branches)
                          if (b != branch) b,
                      ]),
              ),
          ],
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: EteeloTextInput(
                  controller: _input,
                  label: l10n.staffBranchAdd,
                  placeholder: l10n.staffBranchPlaceholder,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              EteeloButton.secondary(
                label: l10n.staffBranchAddAction,
                icon: Icons.add,
                onPressed: _add,
                fullWidth: false,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
