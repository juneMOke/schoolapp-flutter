import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_refusal.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/communication_failure_text.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/states/communication_error_action.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'échec d'un geste (`role=alert`) : l'éditeur reste ouvert et
/// la saisie conservée. L'action suit la famille de l'échec — un 403 ne
/// propose jamais « Réessayer ».
class EditorFailureBanner extends StatelessWidget {
  final Failure failure;
  final AnnouncementEditorBusy? gesture;
  final AnnouncementRefusal? refusal;
  final VoidCallback onRetry;

  const EditorFailureBanner({
    super.key,
    required this.failure,
    required this.gesture,
    required this.refusal,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = incidentOf(failure);
    // Un refus métier ne se corrige pas en rejouant le même appel.
    final action = refusal != null
        ? null
        : communicationErrorAction(context, type, onRetry: onRetry);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.feeStatusDueSoft,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.feeStatusDueBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n),
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _message(l10n, type),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (type == EteeloErrorType.server && incident != null)
                    Text(
                      l10n.communicationErrorIncident(incident),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    action,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (gesture) {
    AnnouncementEditorBusy.sending => l10n.communicationFailureSendTitle,
    AnnouncementEditorBusy.scheduling => l10n.communicationFailureScheduleTitle,
    AnnouncementEditorBusy.cancelling => l10n.communicationFailureCancelTitle,
    _ => l10n.communicationFailureSaveTitle,
  };

  String _message(AppLocalizations l10n, EteeloErrorType type) {
    switch (refusal) {
      case AnnouncementRefusal.channelDisabled:
        return l10n.communicationRefusalChannelDisabled;
      case AnnouncementRefusal.noRecipient:
        return l10n.communicationRefusalNoRecipient;
      case AnnouncementRefusal.incomplete:
        return l10n.communicationRefusalIncomplete;
      default:
        break;
    }
    return switch (type) {
      EteeloErrorType.network => l10n.communicationFailureNetwork,
      EteeloErrorType.unauthorized => l10n.communicationErrorUnauthorized,
      EteeloErrorType.forbidden => l10n.communicationFailureForbidden,
      _ => l10n.communicationFailureServer,
    };
  }
}
