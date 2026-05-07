import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDetailPageStateShell extends StatelessWidget {
  final Widget child;

  const EnrollmentDetailPageStateShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(AppSpacing.lg + 6),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: AppElevation.surface3.copyWith(
            borderRadius: AppRadius.brLg,
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
            color: AppColors.bleuArdoise.withValues(alpha: 0.12),
            borderRadius: AppRadius.brMd,
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.enrollmentDetailLoadingTitle,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enrollmentDetailLoadingMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
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
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.enrollmentDetailLoadErrorTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.enrollmentDetailRetryAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terreCuite,
              foregroundColor: AppColors.textOnDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              elevation: 0,
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
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.enrollmentDetailNotFoundTitle,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enrollmentDetailNotFoundMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
