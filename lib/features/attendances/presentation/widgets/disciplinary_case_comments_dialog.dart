import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Fil de commentaires d'un cas (DF-B) : lecture (`content` SENSIBLE chargé ici)
/// + ajout append-only. Requiert un [DisciplinaryCaseOfflineBloc] **dédié**
/// fourni au-dessus (instance neuve, pour ne pas perturber la liste).
class DisciplinaryCaseCommentsDialog extends StatefulWidget {
  final OfflineDisciplinaryCase caseData;

  const DisciplinaryCaseCommentsDialog({super.key, required this.caseData});

  @override
  State<DisciplinaryCaseCommentsDialog> createState() =>
      _DisciplinaryCaseCommentsDialogState();
}

class _DisciplinaryCaseCommentsDialogState
    extends State<DisciplinaryCaseCommentsDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DisciplinaryCaseOfflineBloc>().add(
      LoadOfflineDisciplinaryComments(widget.caseData.id),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<DisciplinaryCaseOfflineBloc>().add(
      AddOfflineDisciplinaryComment(caseId: widget.caseData.id, content: text),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: EteeloDialogBody(
            // Titres + champ de saisie + bouton ≈ 210 dp incompressibles. En
            // dessous de ce seuil — téléphone en paysage, clavier ouvert — ils
            // rejoignent le défilement au lieu de déborder (mesuré à 189 dp de
            // débordement sur 731×411).
            minPinnedHeight: 260,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.caseData.title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  l10n.disciplinaryCommentsDialogTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],
            ),
            body: _CommentsList(caseId: widget.caseData.id),
            footer: [
              const SizedBox(height: AppDimensions.spacingM),
              _AddField(controller: _controller, onSubmit: _submit),
              const SizedBox(height: AppDimensions.spacingS),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.disciplinaryCommentsCloseAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  final String caseId;

  const _CommentsList({required this.caseId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<
      DisciplinaryCaseOfflineBloc,
      DisciplinaryCaseOfflineState
    >(
      buildWhen: (prev, curr) =>
          curr is DisciplinaryOfflineLoading ||
          curr is DisciplinaryOfflineCommentsLoaded ||
          curr is DisciplinaryOfflineError,
      builder: (context, state) {
        if (state is DisciplinaryOfflineCommentsLoaded) {
          if (state.comments.isEmpty) {
            return Center(
              child: Text(
                l10n.disciplinaryCommentsEmpty,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.separated(
            // Inerte : c'est [EteeloDialogBody] qui porte le défilement, dans
            // ses deux dispositions. Laissée maîtresse du sien, la liste
            // gagnerait l'arène des gestes sans avoir rien à faire défiler, et
            // le doigt de l'utilisateur ne déplacerait plus rien.
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.comments.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spacingS),
            itemBuilder: (_, i) => _CommentTile(comment: state.comments[i]),
          );
        }
        if (state is DisciplinaryOfflineError) {
          return Center(
            child: Text(
              state.message,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DisciplinaryComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(comment.createdAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.content,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            [
              if (comment.authorName != null) comment.authorName!,
              MaterialLocalizations.of(context).formatMediumDate(date),
            ].join(' · '),
            style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AddField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _AddField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Même agrégat, même point d'entrée que l'avancement : le champ d'AJOUT est
    // gardé, la CONSULTATION du fil reste ouverte (elle ne relève que de
    // `discipline.read`, qui a ouvert l'onglet).
    return PermissionGate.access(
      kDisciplineInstructAccess,
      child: SessionWriteGate(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.disciplinaryCommentAddHint,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
              ),
              onPressed: onSubmit,
              child: Text(l10n.disciplinaryCommentAddAction),
            ),
          ],
        ),
      ),
    );
  }
}
