import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_lines.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Cet élève existe peut-être déjà. »
///
/// Posée après l'étape Identité d'une **Première inscription**, quand la sonde
/// a retrouvé quelqu'un dans le corpus local. Elle **avertit**, elle ne conclut
/// pas : le guichet reste seul juge, et « Continuer quand même » est toujours à
/// un geste.
///
/// V1 délibérément **sans carte cliquable** : les routes Inscription partagent
/// un unique `EnrollmentOfflineBloc` sous leur `ShellRoute`, et ouvrir un second
/// dossier ré-hydraterait le wizard resté dessous sur l'autre élève
/// (cf. `DOUBLON_INSCRIPTION_PLAN.md` §D3). Elle nomme donc, et s'arrête là.
class EnrollmentDuplicateDialog extends StatelessWidget {
  final List<EnrollmentDuplicateCandidate> candidates;

  const EnrollmentDuplicateDialog({super.key, required this.candidates});

  /// `true` = le guichet passe outre et poursuit son inscription.
  /// `false` = il retourne corriger sa saisie — croix et barrière comprises.
  ///
  /// Liste vide : rien à dire, donc **rien à montrer**. On rend `true` sans
  /// ouvrir de boîte plutôt que d'afficher un avertissement sans avertissement
  /// — c'est la même règle que « elle ne parle que quand elle trouve ».
  static Future<bool> show(
    BuildContext context, {
    required List<EnrollmentDuplicateCandidate> candidates,
  }) async {
    if (candidates.isEmpty) return true;
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => EnrollmentDuplicateDialog(candidates: candidates),
    );
    return passed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final named = EnrollmentDuplicateLines.named(candidates);
    final others = EnrollmentDuplicateLines.othersCount(candidates);

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: EteeloDialogBody(
          // Pied à deux boutons (~78 dp) sous un en-tête de 86 : au-dessous de
          // ce seuil, tout rejoint le défilement plutôt que de déborder.
          minPinnedHeight: 250,
          header: EteeloDialogDarkHeader(
            eyebrow: l10n.enrollmentDuplicateDialogEyebrow,
            title: l10n.enrollmentDuplicateDialogTitle,
            onClose: () => Navigator.of(context).pop(false),
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.enrollmentDuplicateDialogMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              for (final candidate in named) ...[
                _CandidateLine(candidate: candidate),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              if (others > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
                  child: Text(
                    l10n.enrollmentDuplicateOthers(others),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          footer: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: OutlinedButton.styleFrom(
                        // ⚠️ Sans `minimumSize`, un bouton inline hérite du
                        // thème plein-largeur et lève en contrainte infinie.
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(l10n.enrollmentDuplicateContinueAction),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    // Le bouton plein est « Corriger », pas « Continuer » : le
                    // geste mis en avant est celui qu'on vient de recommander.
                    // Passer outre reste possible d'un seul tap — la sonde ne
                    // bloque jamais — mais l'écran ne le suggère pas.
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(l10n.enrollmentDuplicateFixAction),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un élève retrouvé : son identité, et d'où elle vient.
class _CandidateLine extends StatelessWidget {
  final EnrollmentDuplicateCandidate candidate;

  const _CandidateLine({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.person_search_outlined,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EnrollmentDuplicateLines.identityOf(candidate, l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.bleuProfond,
                  ),
                ),
                Text(
                  EnrollmentDuplicateLines.sourceOf(candidate.source, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
