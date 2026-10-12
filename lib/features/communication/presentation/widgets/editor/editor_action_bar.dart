import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions collante de l'éditeur : enregistrer comme modèle,
/// supprimer ou annuler l'envoi, brouillon, puis envoyer ou programmer.
/// En deçà de 720 dp, les deux derniers passent en pleine largeur.
class EditorActionBar extends StatelessWidget {
  final AnnouncementEditorState state;
  final VoidCallback onDraft;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onSaveAsTemplate;

  const EditorActionBar({
    super.key,
    required this.state,
    required this.onDraft,
    required this.onSubmit,
    required this.onCancel,
    this.onSaveAsTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.busy;
    final idle = busy == null && !state.isLocked;
    final scheduled = state.sendMode == AnnouncementSendMode.scheduled;
    final status = state.announcement?.status;
    final saveAsTemplate = onSaveAsTemplate;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppElevation.shadowRaised,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth <
              AppDimensions.communicationEditorCompactMaxWidth;
          final secondary = <Widget>[
            if (saveAsTemplate != null)
              EteeloButton.ghost(
                label: l10n.communicationSaveAsTemplate,
                icon: Icons.dashboard_customize_outlined,
                onPressed: idle ? saveAsTemplate : null,
                fullWidth: false,
              ),
            if (status != null && status.canCancel)
              EteeloButton.ghost(
                label: status == AnnouncementStatus.draft
                    ? l10n.communicationDelete
                    : l10n.communicationCancelSending,
                icon: Icons.delete_outline,
                isLoading: busy == AnnouncementEditorBusy.cancelling,
                onPressed: idle ? onCancel : null,
                fullWidth: false,
              ),
          ];
          final draft = EteeloButton.secondary(
            label: l10n.communicationSaveDraft,
            icon: Icons.save_outlined,
            isLoading: busy == AnnouncementEditorBusy.saving,
            onPressed: idle ? onDraft : null,
            fullWidth: compact,
          );
          final submit = EteeloButton.primary(
            label: scheduled
                ? l10n.communicationSchedule
                : l10n.communicationSend,
            icon: scheduled
                ? Icons.schedule_send_outlined
                : Icons.send_outlined,
            isLoading:
                busy == AnnouncementEditorBusy.sending ||
                busy == AnnouncementEditorBusy.scheduling,
            loadingLabel: l10n.communicationSending,
            onPressed: idle ? onSubmit : null,
            fullWidth: compact,
          );
          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (secondary.isNotEmpty)
                  Wrap(spacing: AppSpacing.sm, children: secondary),
                const SizedBox(height: AppSpacing.sm),
                draft,
                const SizedBox(height: AppSpacing.sm),
                submit,
              ],
            );
          }
          return Row(
            children: [
              // Les gestes secondaires passent à la ligne plutôt que de pousser
              // les deux principaux hors de l'écran.
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              draft,
              const SizedBox(width: AppSpacing.sm),
              submit,
            ],
          );
        },
      ),
    );
  }
}
