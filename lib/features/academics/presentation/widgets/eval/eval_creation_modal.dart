import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la modale de création d'une évaluation (spec §1) : coque `Modal` 500 dp,
/// en-tête bleu profond avec eyebrow « {branche} — {classe} », fermeture ✕ / voile
/// / Échap. Fournit son `CreateEvaluationBloc` ; résout la [Evaluation] créée (ou
/// `null` si annulée).
Future<Evaluation?> showEvalCreationModal(
  BuildContext context, {
  required CoursNotationDetail detail,
  required String brancheNom,
  required String classroomName,
}) {
  final size = MediaQuery.sizeOf(context);
  final l10n = AppLocalizations.of(context)!;
  return showDialog<Evaluation>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.45),
    builder: (_) => BlocProvider<CreateEvaluationBloc>(
      create: (_) => GetIt.instance<CreateEvaluationBloc>(),
      child: BlocBuilder<CreateEvaluationBloc, CreateEvaluationState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, state) {
          final busy = state.isInProgress;
          return PopScope(
            // Verrouille la fermeture (voile / Échap / retour Android) pendant le
            // POST : sinon la modale peut se fermer alors que la création est en
            // vol → évaluation créée mais non reflétée dans l'UI.
            canPop: !busy,
            child: Dialog(
              backgroundColor: AppColors.surfaceRaised,
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width <= 560 ? AppSpacing.md : AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: size.height * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(
                      eyebrow: '$brancheNom — $classroomName',
                      title: l10n.evalCreateTitle,
                      canClose: !busy,
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: EvalCreationForm(
                          detail: detail,
                          classroomName: classroomName,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final String eyebrow;
  final String title;

  /// ✕ actif seulement hors envoi (aligné sur le bouton « Annuler »).
  final bool canClose;

  const _Header({
    required this.eyebrow,
    required this.title,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.orDoux,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textOnDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canClose ? () => Navigator.of(context).pop() : null,
            icon: const Icon(Icons.close_rounded, color: AppColors.textOnDark),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
