import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_back_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_page_header.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/content_section.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/diffusion_section.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_action_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_banners.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_failure_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui a abouti, et le communiqué tel que le serveur l'a rendu.
typedef EditorDone =
    void Function(AnnouncementEditorOutcome outcome, Announcement announcement);

/// L'éditeur : sections numérotées au-dessus, barre d'actions collante.
class AnnouncementEditorScreen extends StatelessWidget {
  final VoidCallback onBack;
  final EditorDone onDone;
  final DateTime Function() now;

  /// Avant un envoi ou une programmation : la confirmation. `true` pour
  /// poursuivre. Sans elle, l'envoi part tout de suite.
  final Future<bool> Function(BuildContext context)? confirmSubmit;

  const AnnouncementEditorScreen({
    super.key,
    required this.onBack,
    required this.onDone,
    this.now = DateTime.now,
    this.confirmSubmit,
  });

  @override
  Widget build(BuildContext context) =>
      BlocListener<AnnouncementEditorCubit, AnnouncementEditorState>(
        listenWhen: (prev, curr) =>
            curr.outcome != null && prev.outcome != curr.outcome,
        listener: (context, state) {
          final announcement = state.announcement;
          if (announcement != null) onDone(state.outcome!, announcement);
        },
        child: BlocBuilder<AnnouncementEditorCubit, AnnouncementEditorState>(
          builder: (context, state) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _Form(state: state, onBack: onBack, now: now()),
                ),
              ),
              // En lecture seule, aucun geste à offrir.
              if (!state.readOnly)
                EditorActionBar(
                  state: state,
                  onDraft: context.read<AnnouncementEditorCubit>().saveDraft,
                  onSubmit: () => _submit(context),
                  onCancel: () => _cancel(context, state),
                ),
            ],
          ),
        ),
      );

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<AnnouncementEditorCubit>();
    if (!cubit.validateForSubmit()) return;
    final confirm = confirmSubmit;
    if (confirm != null && !await confirm(context)) return;
    if (!context.mounted) return;
    await cubit.submit();
  }

  Future<void> _cancel(
    BuildContext context,
    AnnouncementEditorState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.announcement?.status == AnnouncementStatus.draft;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: draft
          ? l10n.communicationDeleteTitle
          : l10n.communicationCancelSendingTitle,
      message: draft
          ? l10n.communicationDeleteMessage
          : l10n.communicationCancelSendingMessage,
      confirmLabel: draft
          ? l10n.communicationDelete
          : l10n.communicationCancelSending,
      cancelLabel: l10n.communicationKeep,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AnnouncementEditorCubit>().cancel();
  }
}

class _Form extends StatelessWidget {
  final AnnouncementEditorState state;
  final VoidCallback onBack;
  final DateTime now;

  const _Form({required this.state, required this.onBack, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AnnouncementEditorCubit>();
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunicationBackBar(onBack: state.busy == null ? onBack : null),
        const SizedBox(height: AppSpacing.md),
        CommunicationPageHeader(
          eyebrow: l10n.menuCommunication,
          title: state.isNew
              ? l10n.communicationNew
              : l10n.communicationEditTitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        EditorStatusBanner(state: state, now: now),
        if (failure != null) ...[
          EditorFailureBanner(
            failure: failure,
            gesture: state.failedGesture,
            refusal: state.refusal,
            onRetry: cubit.retry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ContentSection(
          state: state,
          onCategory: cubit.setCategory,
          onTitle: cubit.setTitle,
          onBody: cubit.setBody,
        ),
        const SizedBox(height: AppSpacing.lg),
        DiffusionSection(
          number: 2,
          state: state,
          now: now,
          onToggleChannel: cubit.toggleChannel,
          onSendMode: cubit.setSendMode,
          onScheduledAt: cubit.setScheduledAt,
        ),
      ],
    );
  }
}
