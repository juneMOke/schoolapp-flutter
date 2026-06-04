import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsErrorState extends StatelessWidget {
  final EnrollmentErrorType type;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onContactAdmin;

  const EnrollmentResultsErrorState({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
    this.onReconnect,
    this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = _tone;
    final action = _primaryAction(l10n);

    return EteeloEmptyResult(
      label: _title(l10n),
      description: message?.trim().isNotEmpty == true
          ? message!
          : _description(l10n),
      medallionIcon: _icon,
      cornerBadgeIcon: Icons.error_outline_rounded,
      accentColor: tone,
      primaryAction: action == null
          ? null
          : FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon, size: 16),
              label: Text(action.label),
            ),
      autofocusPrimaryAction: action != null,
      fullWidthCard: true,
    );
  }

  _ErrorAction? _primaryAction(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network ||
      EnrollmentErrorType.server ||
      EnrollmentErrorType.unknown =>
        onRetry == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry!,
              ),
      EnrollmentErrorType.unauthorized =>
        onReconnect == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorReconnect,
                icon: Icons.lock_open_rounded,
                onPressed: onReconnect!,
              ),
      EnrollmentErrorType.forbidden =>
        onContactAdmin == null
            ? null
            : _ErrorAction(
                label: l10n.enrollmentErrorContactAdmin,
                icon: Icons.mail_outline_rounded,
                onPressed: onContactAdmin!,
              ),
    };
  }

  String _title(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network => l10n.enrollmentErrorNetworkTitle,
      EnrollmentErrorType.unauthorized => l10n.enrollmentErrorUnauthorizedTitle,
      EnrollmentErrorType.forbidden => l10n.enrollmentErrorForbiddenTitle,
      EnrollmentErrorType.server => l10n.enrollmentErrorServerTitle,
      EnrollmentErrorType.unknown => l10n.enrollmentErrorUnknownTitle,
    };
  }

  String _description(AppLocalizations l10n) {
    return switch (type) {
      EnrollmentErrorType.network => l10n.enrollmentErrorNetworkMessage,
      EnrollmentErrorType.unauthorized =>
        l10n.enrollmentErrorUnauthorizedMessage,
      EnrollmentErrorType.forbidden => l10n.enrollmentErrorForbiddenMessage,
      EnrollmentErrorType.server => l10n.enrollmentErrorServerMessage,
      EnrollmentErrorType.unknown => l10n.enrollmentErrorUnknownMessage,
    };
  }

  Color get _tone {
    return switch (type) {
      EnrollmentErrorType.network => AppColors.info,
      EnrollmentErrorType.unauthorized ||
      EnrollmentErrorType.forbidden => AppColors.warning,
      EnrollmentErrorType.server => AppColors.error,
      EnrollmentErrorType.unknown => AppColors.bleuArdoise,
    };
  }

  IconData get _icon {
    return switch (type) {
      EnrollmentErrorType.network => Icons.wifi_off_rounded,
      EnrollmentErrorType.unauthorized => Icons.lock_outline_rounded,
      EnrollmentErrorType.forbidden => Icons.gpp_bad_rounded,
      EnrollmentErrorType.server => Icons.error_outline_rounded,
      EnrollmentErrorType.unknown => Icons.warning_amber_rounded,
    };
  }
}

class _ErrorAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ErrorAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
