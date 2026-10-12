import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/confirm/announcement_confirm_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la barre d'actions qui passent par une question : envoyer
/// (récapitulatif) et supprimer ou annuler l'envoi (confirmation).
class EditorGestures {
  final BuildContext context;
  final DateTime Function() now;

  /// Faux : l'envoi part sans récapitulatif (variante « Envoi direct »).
  final bool confirmBeforeSending;

  const EditorGestures(
    this.context, {
    required this.now,
    this.confirmBeforeSending = true,
  });

  /// Vrai si le formulaire est incomplet : l'appelant ramène l'utilisateur à
  /// la rédaction.
  Future<bool> submit() async {
    final cubit = context.read<AnnouncementEditorCubit>();
    if (!cubit.validateForSubmit()) return true;
    final reach = context.read<AnnouncementReachCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    // WhatsApp pas encore activé : le serveur refuserait, autant le dire
    // avant la question.
    if (reach.whatsappDisabled) {
      AppSnackBar.showWarning(
        context,
        l10n.communicationRefusalChannelDisabled,
      );
      return false;
    }
    if (confirmBeforeSending) {
      final confirmed = await showAnnouncementConfirmDialog(
        context,
        state: cubit.state,
        reach: reach.reach,
        now: now(),
      );
      if (!confirmed || !context.mounted) return false;
    }
    await cubit.submit();
    return false;
  }

  Future<void> cancel() async {
    final cubit = context.read<AnnouncementEditorCubit>();
    final l10n = AppLocalizations.of(context)!;
    final draft = cubit.state.announcement?.status == AnnouncementStatus.draft;
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
    await cubit.cancel();
  }
}
