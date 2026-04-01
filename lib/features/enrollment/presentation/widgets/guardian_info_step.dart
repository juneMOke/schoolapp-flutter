import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_card.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianInfoStep extends StatelessWidget {
  final List<ParentSummary> parentDetails;

  const GuardianInfoStep({super.key, required this.parentDetails});

  @override
  Widget build(BuildContext context) {
    if (parentDetails.isEmpty) return _buildEmptyState(context);

    return Column(
      children: parentDetails.asMap().entries.map((entry) {
        final index = entry.key;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < parentDetails.length - 1 ? 16 : 0,
          ),
          child: GuardianCard(
            parent: entry.value,
            isPrimary: index == 0,
            number: index + 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noGuardianInfo,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}