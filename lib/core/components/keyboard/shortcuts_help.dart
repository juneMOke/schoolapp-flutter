import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « ? » (ou F1) ouvre la liste des raccourcis clavier : sans elle, ils ne se
/// découvrent qu'au hasard. « ? » s'écrit normalement dans un champ.
class ShortcutsHelpShortcut extends StatelessWidget {
  final Widget child;

  const ShortcutsHelpShortcut({super.key, required this.child});

  static const List<ShortcutActivator> activators = [
    CharacterActivator('?'),
    SingleActivator(LogicalKeyboardKey.f1),
  ];

  @override
  Widget build(BuildContext context) => RouteKeyShortcut(
    activators: activators,
    ignoreWhileTyping: true,
    onPressed: () =>
        EteeloFormDialog.show<void>(context, const ShortcutsHelpDialog()),
    child: child,
  );
}

/// La liste des raccourcis de l'application.
class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enter = l10n.shortcutsKeyEnter;
    final rows = <(List<String>, String)>[
      (['Ctrl+F', '/'], l10n.shortcutsHelpSearch),
      (['Ctrl+B'], l10n.shortcutsHelpSidebar),
      (['Ctrl+N'], l10n.shortcutsHelpCreate),
      (['F5', 'Ctrl+R'], l10n.shortcutsHelpRefresh),
      (['Ctrl+P'], l10n.shortcutsHelpPrint),
      (['↑', '↓'], l10n.shortcutsHelpRows),
      ([enter], l10n.shortcutsHelpOpen),
      (['Ctrl+$enter'], l10n.shortcutsHelpSubmit),
      ([l10n.shortcutsKeyEscape], l10n.shortcutsHelpClose),
      (['Ctrl+${l10n.shortcutsKeyClick}'], l10n.shortcutsHelpNewTab),
      (['?', 'F1'], l10n.shortcutsHelpThis),
    ];
    return EteeloFormDialog(
      title: l10n.shortcutsHelpTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (keys, label) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [for (final key in keys) _KeyCap(key)],
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;

  const _KeyCap(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadius.brSm,
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
    ),
  );
}
