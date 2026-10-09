import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_labels.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_notice.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_target_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Modale « Désactiver » — la même pour un élève ou pour N. Se ferme sur le
/// nombre d'élèves désactivés ; reste ouverte, saisie conservée, en cas
/// d'échec. Non fermable pendant l'écriture.
class SuspendDialog extends StatefulWidget {
  final List<SuspensionCandidate> candidates;

  /// Le jour affiché comme date d'effet.
  final DateTime today;

  const SuspendDialog({
    super.key,
    required this.candidates,
    required this.today,
  });

  @override
  State<SuspendDialog> createState() => _SuspendDialogState();
}

class _SuspendDialogState extends State<SuspendDialog> {
  final TextEditingController _precision = TextEditingController();
  SuspensionReason? _reason;

  @override
  void dispose() {
    _precision.dispose();
    super.dispose();
  }

  void _submit() => context.read<SuspensionGestureCubit>().suspend(
    [for (final c in widget.candidates) c.target],
    reason: _reason,
    precision: _precision.text,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = widget.candidates.length;
    return BlocConsumer<SuspensionGestureCubit, SuspensionGestureState>(
      listenWhen: (_, state) => state is SuspensionGestureDone,
      listener: (context, state) =>
          Navigator.of(context).pop((state as SuspensionGestureDone).count),
      builder: (context, state) {
        final busy = state is SuspensionGestureBusy;
        return PopScope(
          canPop: !busy,
          child: EteeloFormDialog(
            eyebrow: l10n.suspensionDialogEyebrow,
            title: l10n.suspensionDialogTitle(count),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SuspensionTargetHeader(candidates: widget.candidates),
                const SizedBox(height: AppSpacing.lg),
                SuspensionNotice(
                  lead: l10n.suspensionDialogInfoLead(widget.today),
                  body: l10n.suspensionDialogInfoBody,
                ),
                const SizedBox(height: AppSpacing.lg),
                EteeloSelectInput<SuspensionReason?>(
                  label: l10n.suspensionReasonLabel,
                  value: _reason,
                  enabled: !busy,
                  items: [
                    EteeloSelectItem(
                      value: null,
                      label: l10n.suspensionReasonNone,
                    ),
                    for (final reason in SuspensionReason.values)
                      EteeloSelectItem(
                        value: reason,
                        label: reason.label(l10n),
                      ),
                  ],
                  onChanged: (value) => setState(() => _reason = value),
                ),
                const SizedBox(height: AppSpacing.md),
                EteeloTextInput(
                  controller: _precision,
                  label: l10n.suspensionPrecisionLabel,
                  placeholder: l10n.suspensionPrecisionHint,
                  // Un texte libre : première lettre seulement.
                  capitalization: EteeloTextCapitalization.sentence,
                  enabled: !busy,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      StudentSuspension.precisionMaxLength,
                    ),
                  ],
                ),
                if (state is SuspensionGestureFailed)
                  SuspensionGestureError(message: l10n.suspensionWriteFailed),
              ],
            ),
            actions: [
              EteeloButton.ghost(
                label: l10n.suspensionCancel,
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                fullWidth: false,
              ),
              EteeloButton.primary(
                label: l10n.suspensionConfirm(count),
                icon: Icons.person_remove_outlined,
                isLoading: busy,
                loadingLabel: l10n.suspensionBusy,
                onPressed: _submit,
                fullWidth: false,
              ),
            ],
          ),
        );
      },
    );
  }
}
