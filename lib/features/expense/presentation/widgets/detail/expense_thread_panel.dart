import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_act_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_composer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le fil d'une demande, au bas de sa fiche : un message par geste, horodaté,
/// jamais effaçable.
///
/// Écrire dans le fil **est** un geste : le champ ne s'offre donc qu'à qui
/// détient `expense.write`, et la propriété n'y entre pas — commenter la
/// demande d'un collègue est tout l'objet de la route dédiée (Q1).
class ExpenseThreadPanel extends StatelessWidget {
  /// `null` quand le fil n'a **pas pu être lu** — une panne de la base locale,
  /// qui ne se confond pas avec un fil vide.
  final List<ExpenseMessage>? messages;

  /// Le compte de la session : ce qui distingue ses propres messages (F24).
  final String? accountId;

  /// Envoie un commentaire ; `null` laisse le fil en lecture seule — un fil
  /// illisible n'a pas de place où écrire.
  final Future<ExpenseCommentResult> Function(String body)? onSend;

  const ExpenseThreadPanel({
    super.key,
    required this.messages,
    this.accountId,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final thread = messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: AppDimensions.detailMiniIconSize,
              color: AppColors.bleuArdoise,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.expenseThreadTitle, style: AppTextStyles.bodyStrong),
            if (thread != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.expenseThreadCount(thread.length),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (thread == null)
          _Note(
            text: l10n.expenseThreadUnreadable,
            color: AppColors.error,
            icon: Icons.error_outline,
          )
        else if (thread.isEmpty)
          // Un fil vide n'est pas une recherche sans résultat : il ne prend
          // donc pas l'anatomie du vide, qui appelle une action. Il n'y a rien
          // à faire ici, seulement rien à lire encore.
          _Note(text: l10n.expenseThreadEmpty, color: AppColors.textMuted)
        else
          for (final message in thread)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: _Message(
                message: message,
                mine: message.isMine(accountId),
              ),
            ),
        // Rien à écrire sous un fil qu'on n'a pas su lire : on ne sait pas ce
        // que le message viendrait compléter.
        if (onSend != null && thread != null)
          ExpenseThreadComposer(onSend: onSend!),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Note({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(
      color: color,
      fontStyle: icon == null ? FontStyle.italic : null,
    );
    final label = icon;
    if (label == null) return Text(text, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(label, size: AppDimensions.detailMiniIconSize, color: color),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Un message : la vignette de son acte, puis la bulle. Celle du compte de la
/// session prend le fond de marque — un repère, jamais une information : le nom
/// de l'auteur est écrit dans la bulle, la couleur ne porte rien seule.
class _Message extends StatelessWidget {
  final ExpenseMessage message;
  final bool mine;

  const _Message({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final visuals = expenseActVisuals(message.act);
    final act = message.act;
    // L'horloge est rangée en UTC et se lit à l'heure du poste.
    final moment = message.createdAt.toLocal();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppDimensions.expenseThreadMedallionSize,
          height: AppDimensions.expenseThreadMedallionSize,
          margin: const EdgeInsets.only(top: AppDimensions.spacingXS / 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(
              AppDimensions.expenseThreadMedallionRadius,
            ),
          ),
          child: Icon(
            visuals.icon,
            size: AppDimensions.expenseThreadMedallionIconSize,
            color: visuals.ink,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.expenseNotePaddingV,
              horizontal: AppDimensions.expenseThreadBubblePaddingH,
            ),
            decoration: BoxDecoration(
              color: mine ? AppColors.bleuArdoiseSoft : AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(
                AppDimensions.expenseThreadBubbleRadius,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message.authorName ?? l10n.expenseNoValue,
                        style: AppTextStyles.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    message.isPending || message.isRejected
                        ? ExpenseThreadStateTag(rejected: message.isRejected)
                        : Text(
                            l10n.expenseJoin(
                              dates.formatShortMonthDay(moment),
                              dates.formatTimeOfDay(
                                TimeOfDay.fromDateTime(moment),
                              ),
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                  ],
                ),
                if (act != null)
                  Text(
                    expenseActLabel(l10n, act),
                    style: AppTextStyles.caption.copyWith(color: visuals.ink),
                  ),
                // Un `EDIT` arrive au corps vide : le serveur ne fabrique aucun
                // texte, le libellé de l'acte suffit.
                if (message.body.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacingXS / 2),
                  Text(
                    message.body,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
