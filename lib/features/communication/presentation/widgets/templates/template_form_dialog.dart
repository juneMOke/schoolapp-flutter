import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/category_picker.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/counted_text_field.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/variable_insert_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale enregistre ; rend l'échec, ou `null`.
typedef TemplateSave =
    Future<Failure?> Function(
      AnnouncementCategory category,
      String title,
      String body,
    );

/// Créer ou modifier un modèle : catégorie, titre, message — tous les champs
/// insérables actifs, puisque l'audience n'est pas encore choisie.
Future<bool> showTemplateFormDialog(
  BuildContext context, {
  required TemplateSave onSave,
  AnnouncementTemplate? template,
}) async =>
    await EteeloFormDialog.show<bool>(
      context,
      _TemplateFormDialog(template: template, onSave: onSave),
    ) ??
    false;

class _TemplateFormDialog extends StatefulWidget {
  final AnnouncementTemplate? template;
  final TemplateSave onSave;

  const _TemplateFormDialog({required this.template, required this.onSave});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  late var _category = widget.template?.category ?? AnnouncementCategory.info;
  late final _title = TextEditingController(text: widget.template?.title);
  late final _body = TextEditingController(text: widget.template?.body);
  var _showErrors = false;
  var _saving = false;
  Failure? _failure;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _complete =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  void _insert(AnnouncementVariable variable) {
    final selection = _body.selection;
    final inserted = AnnouncementVariables.insert(
      _body.text,
      variable,
      start: selection.start,
      end: selection.end,
    );
    if (inserted.text.length > AnnouncementContent.bodyMaxLength) return;
    setState(
      () => _body.value = TextEditingValue(
        text: inserted.text,
        selection: TextSelection.collapsed(offset: inserted.cursor),
      ),
    );
  }

  Future<void> _save() async {
    if (!_complete) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(_category, _title.text, _body.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    return EteeloFormDialog(
      maxWidth: AppDimensions.communicationTemplateModalMaxWidth,
      title: widget.template == null
          ? l10n.communicationTemplateCreate
          : l10n.communicationTemplateEditTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryPicker(
            value: _category,
            onChanged: _saving
                ? null
                : (category) => setState(() => _category = category),
          ),
          const SizedBox(height: AppSpacing.md),
          CountedTextField(
            controller: _title,
            label: l10n.communicationTitleLabel,
            maxLength: AnnouncementContent.titleMaxLength,
            enabled: !_saving,
            errorText: _showErrors && _title.text.trim().isEmpty
                ? l10n.communicationTitleRequired
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          VariableInsertBar(
            amountAllowed: true,
            onInsert: _saving ? null : _insert,
          ),
          const SizedBox(height: AppSpacing.sm),
          CountedTextField(
            controller: _body,
            label: l10n.communicationBodyLabel,
            maxLength: AnnouncementContent.bodyMaxLength,
            multiline: true,
            lines: 6,
            enabled: !_saving,
            hint: l10n.communicationTemplateHint,
            errorText: _showErrors && _body.text.trim().isEmpty
                ? l10n.communicationBodyRequired
                : null,
            onChanged: (_) => setState(() {}),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.communicationTemplateSaveFailed,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.communicationCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.communicationTemplateSave,
          icon: Icons.save_outlined,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
          fullWidth: false,
        ),
      ],
    );
  }
}
