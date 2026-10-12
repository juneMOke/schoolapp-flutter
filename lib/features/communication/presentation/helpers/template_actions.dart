import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/template_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes d'écriture sur les modèles, chacun suivi de son toast.
class TemplateActions {
  final BuildContext context;
  final AnnouncementTemplatesCubit cubit;

  const TemplateActions(this.context, this.cubit);

  Future<void> create() async {
    final saved = await showTemplateFormDialog(
      context,
      onSave: (category, title, body) =>
          cubit.create(category: category, title: title, body: body),
    );
    if (saved && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.communicationTemplateSaved,
      );
    }
  }

  Future<void> edit(AnnouncementTemplate template) async {
    final saved = await showTemplateFormDialog(
      context,
      template: template,
      onSave: (category, title, body) => cubit.update(
        AnnouncementTemplate(
          id: template.id,
          category: category,
          title: title,
          body: body,
        ),
      ),
    );
    if (saved && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.communicationTemplateSaved,
      );
    }
  }

  Future<void> delete(AnnouncementTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.communicationTemplateDeleteTitle,
      message: l10n.communicationTemplateDeleteMessage,
      confirmLabel: l10n.communicationDelete,
      cancelLabel: l10n.communicationKeep,
      isDestructive: true,
    );
    if (!confirmed) return;
    final failure = await cubit.delete(template.id);
    if (!context.mounted) return;
    if (failure == null) {
      AppSnackBar.showSuccess(context, l10n.communicationTemplateDeleted);
    } else {
      AppSnackBar.showError(context, l10n.communicationTemplateDeleteFailed);
    }
  }
}
