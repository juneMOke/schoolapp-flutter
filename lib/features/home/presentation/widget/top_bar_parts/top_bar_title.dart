import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class TopBarTitle extends StatelessWidget {
  final String title;
  final bool isPreRegistrations;

  const TopBarTitle({
    super.key,
    required this.title,
    required this.isPreRegistrations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isPreRegistrations
                ? Icons.assignment_outlined
                : Icons.dashboard_customize_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            if (isPreRegistrations)
              const Text(
                'Suivi des dossiers en attente',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
