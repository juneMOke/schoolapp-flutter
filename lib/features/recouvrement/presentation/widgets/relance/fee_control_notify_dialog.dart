import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_recipient_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que fait « Envoyer » du message relu. Un échec se signale en **levant** :
/// la sur-couche le dit et garde le texte.
typedef FeeControlNotifySend = Future<void> Function(String message);

/// **O4 · Relance des parents** — « Notifier {n} parent(s) ».
///
/// Le message prérempli se relit et se corrige ; les destinataires se
/// vérifient, ceux sans téléphone à part. « Envoyer » appelle [onSend] — la
/// page y remet un PDF au partage de l'appareil (Q4 : l'application n'envoie
/// aucun SMS elle-même) — puis referme la sur-couche sur `true`. Plein écran
/// sous 760 de fenêtre (A11), comme toute `EteeloFormDialog`.
///
/// Ouvrir par [show] : le résultat dit si la relance est partie.
class FeeControlNotifyDialog extends StatefulWidget {
  /// Frais · classe — la question à laquelle la relance répond.
  final String contextLabel;
  final String initialMessage;
  final List<FeeControlNotifyRecipient> recipients;
  final FeeControlNotifySend onSend;

  const FeeControlNotifyDialog({
    super.key,
    required this.contextLabel,
    required this.initialMessage,
    required this.recipients,
    required this.onSend,
  });

  static Future<bool> show(
    BuildContext context,
    FeeControlNotifyDialog dialog,
  ) async => await EteeloFormDialog.show<bool>(context, dialog) ?? false;

  @override
  State<FeeControlNotifyDialog> createState() => _FeeControlNotifyDialogState();
}

class _FeeControlNotifyDialogState extends State<FeeControlNotifyDialog> {
  late final TextEditingController _message = TextEditingController(
    text: widget.initialMessage,
  );
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Un double toucher ne fait qu'un envoi (I12) : le second trouve
  /// `_sending` levé, et le bouton est déjà inactif au rendu suivant.
  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await widget.onSend(_message.text);
    } catch (_) {
      if (!mounted) return;
      // Le texte saisi reste dans le champ : rien n'est réinitialisé.
      setState(() {
        _sending = false;
        _failed = true;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final send = _sending ? null : _send;

    return EteeloFormDialog(
      eyebrow: l10n.feeControlNotifyEyebrow,
      title: l10n.feeControlNotifyTitle(widget.recipients.length),
      maxWidth: AppDimensions.recoveryNotifyDialogMaxWidth,
      onSubmit: send,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.contextLabel.isNotEmpty) ...[
            Text(
              widget.contextLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          FeeControlNotifySectionLabel(l10n.feeControlNotifyMessageLabel),
          EteeloTextInput(
            controller: _message,
            label: l10n.feeControlNotifyMessageLabel,
            hideLabel: true,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 4,
            maxLines: 8,
            enabled: !_sending,
          ),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _message,
            builder: (_, value, _) => Text(
              l10n.feeControlNotifyCharacterCount(value.text.length),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.feeControlNotifyShareNote,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_failed) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: EteeloNotice.error(l10n.feeControlNotifyFailed),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FeeControlNotifyRecipientList(recipients: widget.recipients),
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.cancel,
          icon: Icons.close,
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          key: const ValueKey('fee-control-notify-send'),
          label: l10n.feeControlNotifySend,
          icon: Icons.send_outlined,
          isLoading: _sending,
          loadingLabel: l10n.feeControlNotifySending,
          onPressed: send,
          fullWidth: false,
        ),
      ],
    );
  }
}
