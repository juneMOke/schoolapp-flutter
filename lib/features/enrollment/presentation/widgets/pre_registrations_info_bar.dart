import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class PreRegistrationsInfoBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  final Future<void> Function()? onRefresh;

  const PreRegistrationsInfoBar({
    super.key,
    required this.count,
    required this.isLoading,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.14),
            const Color(0xFF10B981).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? 'Chargement des pré-inscriptions...'
                  : '$count dossier${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRE_REGISTERED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Actualiser',
            child: IconButton(
              onPressed: isLoading || onRefresh == null
                  ? null
                  : () => onRefresh!(),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
