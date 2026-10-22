import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Un geste qui porte un mot : le motif d'un renvoi de paie, le mot de
/// l'école à un parent. Rend le texte saisi (rogné, vide permis quand le mot
/// est facultatif), ou `null` si le geste est abandonné.
///
/// Les libellés viennent de l'appelant : la modale ne connaît aucun domaine.
class EteeloReasonDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String fieldLabel;

  /// Le message sous le champ quand un mot obligatoire manque.
  final String requiredError;
  final String? hint;

  /// Sous le champ, toujours : à qui le mot sera montré.
  final String? helper;
  final bool destructive;
  final bool isRequired;

  /// La saisie s'arrête à cette longueur (rognage compris côté serveur).
  final int? maxLength;

  const EteeloReasonDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.fieldLabel,
    required this.requiredError,
    this.hint,
    this.helper,
    this.destructive = false,
    this.isRequired = true,
    this.maxLength,
  });

  static Future<String?> show(
    BuildContext context,
    EteeloReasonDialog dialog,
  ) => EteeloFormDialog.show<String>(context, dialog);

  @override
  State<EteeloReasonDialog> createState() => _EteeloReasonDialogState();
}

class _EteeloReasonDialogState extends State<EteeloReasonDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty && widget.isRequired) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hint;
    final helper = widget.helper;
    final maxLength = widget.maxLength;
    return EteeloFormDialog(
      onSubmit: _confirm,
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null) ...[
            Text(
              hint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          EteeloTextInput(
            controller: _reason,
            label: widget.fieldLabel,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 4,
            maxLines: 4,
            required: widget.isRequired,
            inputFormatters: [
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            errorText: _showError ? widget.requiredError : null,
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              helper,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: widget.cancelLabel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        widget.destructive
            ? EteeloButton.danger(
                label: widget.confirmLabel,
                onPressed: _confirm,
                fullWidth: false,
              )
            : EteeloButton.primary(
                label: widget.confirmLabel,
                onPressed: _confirm,
                fullWidth: false,
              ),
      ],
    );
  }
}
