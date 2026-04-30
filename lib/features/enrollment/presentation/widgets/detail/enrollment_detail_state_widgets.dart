import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDetailPageStateShell extends StatelessWidget {
  final Widget child;

  const EnrollmentDetailPageStateShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F8FF), Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(22),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class EnrollmentDetailLoadingTemplate extends StatelessWidget {
  const EnrollmentDetailLoadingTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.enrollmentDetailLoadingTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enrollmentDetailLoadingMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class EnrollmentDetailErrorTemplate extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const EnrollmentDetailErrorTemplate({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.enrollmentDetailLoadErrorTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(l10n.enrollmentDetailRetryAction),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class EnrollmentDetailEmptyTemplate extends StatelessWidget {
  const EnrollmentDetailEmptyTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.inbox_outlined,
          size: 42,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.enrollmentDetailNotFoundTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enrollmentDetailNotFoundMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
