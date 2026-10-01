import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une conséquence de la clôture, telle que la modale la liste.
typedef PresenceCloseLine = ({String text, IconData icon});

/// Confirmer la clôture d'un mois : ce qu'elle transmet ([consequences]),
/// les jours sans pointage comptés présents ([notMarkedWarning]) et ce
/// qu'elle fige — sans retour. Rend `true` pour clôturer.
class PresenceMonthCloseDialog extends StatelessWidget {
  final String title;
  final List<PresenceCloseLine> consequences;

  /// `null` : tout est pointé.
  final String? notMarkedWarning;
  final String confirmLabel;

  const PresenceMonthCloseDialog({
    super.key,
    required this.title,
    required this.consequences,
    required this.confirmLabel,
    this.notMarkedWarning,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notMarked = notMarkedWarning;
    return EteeloFormDialog(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in consequences)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PresenceWarning(
                message: line.text,
                icon: line.icon,
                tone: PresenceStatus.none,
              ),
            ),
          if (notMarked != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PresenceWarning(
                icon: Icons.back_hand_outlined,
                message: notMarked,
              ),
            ),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.absent,
            message: l10n.presenceMarkCloseIrreversible,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkCancel,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: confirmLabel,
          icon: Icons.lock,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }
}
