import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de l'éditeur du sujet (spec S4) : « Annuler » (« Fermer » sans
/// modification) et « Enregistrer le sujet », désactivé tant que rien ne
/// change.
class SujetEditorBar extends StatelessWidget {
  final SujetDraftController draft;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const SujetEditorBar({
    super.key,
    required this.draft,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        final dirty = draft.isDirty;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EteeloButton.secondary(
                label: dirty ? l10n.sujetCancel : l10n.sujetClose,
                fullWidth: false,
                onPressed: saving ? null : onCancel,
              ),
              const SizedBox(width: AppSpacing.sm),
              SessionWriteGate(
                child: EteeloButton.primary(
                  label: l10n.sujetSave,
                  loadingLabel: l10n.sujetSaving,
                  icon: Icons.check_rounded,
                  isLoading: saving,
                  fullWidth: false,
                  onPressed: dirty && !saving ? onSave : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
