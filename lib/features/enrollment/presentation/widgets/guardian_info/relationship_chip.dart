import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class RelationshipChip extends StatelessWidget {
  final RelationshipType relationshipType;

  const RelationshipChip({super.key, required this.relationshipType});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getLabel(context),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() => switch (relationshipType) {
    RelationshipType.father     => Colors.blue[600]!,
    RelationshipType.mother     => Colors.pink[600]!,
    RelationshipType.guardian   => Colors.purple[600]!,
    RelationshipType.uncle      => Colors.orange[600]!,
    RelationshipType.aunt       => Colors.deepPurple[400]!,
    RelationshipType.grandparent => Colors.teal[600]!,
    RelationshipType.other      => Colors.grey[600]!,
  };

  IconData _getIcon() => switch (relationshipType) {
    RelationshipType.father     => Icons.man,
    RelationshipType.mother     => Icons.woman,
    RelationshipType.guardian   => Icons.supervisor_account,
    RelationshipType.uncle      => Icons.man_2,
    RelationshipType.aunt       => Icons.woman_2,
    RelationshipType.grandparent => Icons.elderly,
    RelationshipType.other      => Icons.person,
  };

  String _getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (relationshipType) {
      RelationshipType.father     => l10n.relationshipFather,
      RelationshipType.mother     => l10n.relationshipMother,
      RelationshipType.guardian   => l10n.relationshipGuardian,
      RelationshipType.uncle      => l10n.relationshipUncle,
      RelationshipType.aunt       => l10n.relationshipAunt,
      RelationshipType.grandparent => l10n.relationshipGrandparent,
      RelationshipType.other      => l10n.relationshipOther,
    };
  }
}
