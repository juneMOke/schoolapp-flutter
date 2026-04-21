import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class EnrollmentDetailBackButton extends StatefulWidget {
  const EnrollmentDetailBackButton({super.key});

  @override
  State<EnrollmentDetailBackButton> createState() =>
      _EnrollmentDetailBackButtonState();
}

class _EnrollmentDetailBackButtonState
    extends State<EnrollmentDetailBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: 'Retour',
          preferBelow: false,
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppTheme.primaryColor.withValues(alpha: 0.10)
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hovered
                      ? AppTheme.primaryColor.withValues(alpha: 0.30)
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: _hovered
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
