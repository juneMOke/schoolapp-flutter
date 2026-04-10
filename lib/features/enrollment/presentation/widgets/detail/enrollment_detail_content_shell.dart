import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class EnrollmentDetailContentShell extends StatelessWidget {
  final Widget infoBar;
  final Widget child;

  const EnrollmentDetailContentShell({
    super.key,
    required this.infoBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4F8FF),
            Color(0xFFEFF5FF),
            Color(0xFFF7FAFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -45,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.largePadding),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  infoBar,
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}