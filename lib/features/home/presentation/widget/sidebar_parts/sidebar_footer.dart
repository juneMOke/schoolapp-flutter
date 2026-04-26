import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

class SidebarFooter extends StatelessWidget {
  final bool isExpanded;

  const SidebarFooter({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outCurve,
      margin: EdgeInsets.fromLTRB(isExpanded ? 12 : 8, 8, isExpanded ? 12 : 8, 12),
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: isExpanded
          ? const Row(
              children: [
                Icon(Icons.verified_outlined, color: Colors.white60, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dashboard scolaire',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            )
          : const Icon(Icons.verified_outlined, color: Colors.white60, size: 16),
    );
  }
}