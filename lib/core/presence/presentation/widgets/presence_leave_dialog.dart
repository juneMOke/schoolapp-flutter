import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que décide la popin de sortie d'un jour pointé mais pas validé.
enum PresenceLeaveChoice {
  /// Rester sur le jour.
  stay,

  /// Partir sans valider : les pointages restent sur la tablette.
  leave,

  /// Valider d'abord (la modale de validation s'enchaîne), puis partir.
  validate,
}

/// La popin de sortie, en modale carte ([EteeloCardDialog]) : ce qui est
/// gardé et ce qui reste à pointer, puis Rester · Quitter sans valider ·
/// Valider et quitter — l'action qui répare l'oubli, là où on le voit.
class PresenceLeaveDialog extends StatelessWidget {
  /// « Le rapport du mardi 27 octobre n'est pas validé ».
  final String title;

  /// Ce qui est gardé, et combien restent à pointer.
  final String message;

  /// Faux : pas de « Valider et quitter » (le compte ne valide pas d'ici).
  final bool canValidate;

  const PresenceLeaveDialog({
    super.key,
    required this.title,
    required this.message,
    this.canValidate = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void close(PresenceLeaveChoice choice) => Navigator.of(context).pop(choice);
    return EteeloCardDialog(
      eyebrow: l10n.presenceMarkLeaveEyebrow,
      title: title,
      onClose: () => close(PresenceLeaveChoice.stay),
      onSubmit: canValidate ? () => close(PresenceLeaveChoice.validate) : null,
      body: PresenceWarning(
        icon: Icons.pending_actions_outlined,
        message: message,
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkLeaveStay,
          onPressed: () => close(PresenceLeaveChoice.stay),
        ),
        EteeloButton.secondary(
          label: l10n.presenceMarkLeaveConfirm,
          icon: Icons.logout_rounded,
          onPressed: () => close(PresenceLeaveChoice.leave),
        ),
        if (canValidate)
          EteeloButton.primary(
            label: l10n.presenceMarkLeaveValidate,
            icon: Icons.task_alt,
            onPressed: () => close(PresenceLeaveChoice.validate),
          ),
      ],
    );
  }
}
