import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_item.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

class GuardianInfoStepBody extends StatelessWidget {
  final List<ParentSummary> parentDetails;
  final ParentItemStateChanged onItemStateChanged;
  final ParentItemValueChanged onItemValueChanged;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final VoidCallback onSave;

  const GuardianInfoStepBody({
    super.key,
    required this.parentDetails,
    required this.onItemStateChanged,
    required this.onItemValueChanged,
    this.isLoading = false,
    this.canSave = false,
    this.showInlineSaveButton = true,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
            ),
          );
        }),
        if (showInlineSaveButton)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: canSave && !isLoading ? onSave : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
      ],
    );
  }
}