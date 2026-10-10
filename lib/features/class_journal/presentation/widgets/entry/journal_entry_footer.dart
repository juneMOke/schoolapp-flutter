import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied de la modale : « Vider la séance » (si elle a une saisie), puis
/// Annuler et Enregistrer. Pendant l'écriture, tout est inactif et Enregistrer
/// tourne.
class JournalEntryFooter extends StatelessWidget {
  final bool canClear;

  const JournalEntryFooter({super.key, required this.canClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<JournalEntryCubit, JournalEntryState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final cubit = context.read<JournalEntryCubit>();
        final busy = state.isBusy;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (canClear)
              SessionWriteGate(
                child: EteeloButton.ghost(
                  label: l10n.journalClear,
                  icon: Icons.restart_alt_rounded,
                  onPressed: busy ? null : cubit.clear,
                  fullWidth: false,
                ),
              )
            else
              const SizedBox.shrink(),
            Wrap(
              spacing: AppSpacing.md,
              children: [
                EteeloButton.secondary(
                  label: l10n.cancel,
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  fullWidth: false,
                ),
                SessionWriteGate(
                  child: EteeloButton.primary(
                    label: l10n.journalSave,
                    icon: Icons.check_rounded,
                    isLoading: state.status == JournalEntryStatus.saving,
                    onPressed: busy ? null : cubit.save,
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
