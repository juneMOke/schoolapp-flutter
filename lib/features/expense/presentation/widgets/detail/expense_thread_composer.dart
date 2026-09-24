import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend l'envoi d'un commentaire : s'il a été **écrit**, et le fil tel
/// qu'il est ensuite.
///
/// Champs nommés, et les deux sont nécessaires : un message écrit dont la
/// relecture échoue n'est pas un échec d'envoi — annoncer « non envoyé »
/// pousserait l'agent à le retaper, et le fil en porterait deux.
typedef ExpenseCommentResult = ({bool sent, List<ExpenseMessage>? thread});

/// Le champ de saisie du fil — le geste « commenter » (Q1).
///
/// Sous `expense.write`, **sans contrôle de propriété** : c'est ce qui permet
/// au validateur de répondre à la demande d'un collègue, et c'est pour cela
/// que le back lui a donné sa propre route.
///
/// L'échec se dit **ici**, jamais par un toast : une `SnackBar` levée sous une
/// modale est inatteignable, et l'agent croirait son message parti.
class ExpenseThreadComposer extends StatefulWidget {
  final Future<ExpenseCommentResult> Function(String body) onSend;

  const ExpenseThreadComposer({super.key, required this.onSend});

  @override
  State<ExpenseThreadComposer> createState() => _ExpenseThreadComposerState();
}

class _ExpenseThreadComposerState extends State<ExpenseThreadComposer> {
  final TextEditingController _body = TextEditingController();
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    // Un commentaire vide n'est pas un commentaire : rien ne part, et rien
    // n'est reproché — le bouton n'avait simplement rien à envoyer.
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final result = await widget.onSend(body);
    // `mounted` après chaque await : la fiche a pu se fermer entre-temps.
    if (!mounted) return;
    setState(() {
      _sending = false;
      _failed = !result.sent;
      if (result.sent) _body.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate.access(
      kExpenseWriteAccess,
      child: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloTextInput(
              controller: _body,
              label: l10n.expenseThreadComposerLabel,
              placeholder: l10n.expenseThreadComposerHint,
              maxLines: 2,
              enabled: !_sending,
              errorText: _failed ? l10n.expenseThreadSendFailed : null,
              onChanged: (_) {
                if (_failed) setState(() => _failed = false);
              },
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Align(
              alignment: Alignment.centerRight,
              child: EteeloButton.secondary(
                label: l10n.expenseGestureComment,
                icon: Icons.send_outlined,
                onPressed: _sending ? null : _send,
                fullWidth: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Où en est un message : « en attente d'envoi » tant que le serveur ne l'a
/// pas accusé, « non envoyé » quand il ne partira plus.
///
/// Les deux prennent la **place de l'horloge**, et c'est tout l'enjeu : un
/// message mort qui montrerait sa date se lirait comme un geste qui a eu
/// lieu. Un mot, pas une couleur seule — le fil porte déjà des teintes de
/// décision, et une nuance de plus n'y serait pas lue.
class ExpenseThreadStateTag extends StatelessWidget {
  final bool rejected;

  const ExpenseThreadStateTag({super.key, required this.rejected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      rejected ? l10n.expenseThreadRejected : l10n.expenseThreadPending,
      style: AppTextStyles.caption.copyWith(
        color: rejected
            ? AppColors.feeStatusDue
            : AppColors.feeStatusPartialInk,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
