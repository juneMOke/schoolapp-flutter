import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_state.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_pdf.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_options.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/copie/copie_history.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/copie/copie_options_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/copie/copie_viewer.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_section_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Copie » du détail (spec S5) : ce qui figure sur la copie, la
/// visionneuse pour l'imprimer ou la partager, les compteurs et l'historique.
class CopieSection extends StatefulWidget {
  final SujetCopieContent content;
  final CopieState state;
  final ValueChanged<({CopieKind kind, bool corrige})> onDiffused;

  const CopieSection({
    super.key,
    required this.content,
    required this.state,
    required this.onDiffused,
  });

  @override
  State<CopieSection> createState() => _CopieSectionState();
}

class _CopieSectionState extends State<CopieSection> {
  CopieOptions _options = const CopieOptions();

  /// La copie se construit (polices, PDF) : un second appui n'ouvre pas une
  /// seconde visionneuse.
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final options = _options;
    setState(() => _opening = true);
    await openCopieViewer(
      context,
      content: widget.content,
      options: options,
      onDiffused: (kind) =>
          widget.onDiffused((kind: kind, corrige: options.reponses)),
    );
    if (!mounted) return;
    setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final hasQuestions = widget.content.sujet.questions.isNotEmpty;
    return EvalSectionCard(
      title: l10n.copieSectionTitle,
      subtitle: copieSubtitle(l10n, state.printCount, state.shareCount),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.copieOptionsLabel,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CopieOptionsBar(
            options: _options,
            onChanged: (o) => setState(() => _options = o),
          ),
          if (_options.reponses) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: AppDimensions.sujetIconSize,
                  color: AppColors.academicsScoreWeak,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    l10n.copieCorrigeWarning,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warningInk,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EteeloButton.primary(
                label: _options.reponses
                    ? l10n.copieShowCorrige
                    : l10n.copieShow,
                icon: Icons.visibility_outlined,
                fullWidth: false,
                isLoading: _opening,
                onPressed: hasQuestions && !_opening ? _open : null,
              ),
              NotationPill(
                color: AppColors.textSecondary,
                soft: AppColors.surfaceAlt,
                icon: Icons.print_outlined,
                label: l10n.copiePrintCount(state.printCount),
              ),
              NotationPill(
                color: AppColors.textSecondary,
                soft: AppColors.surfaceAlt,
                icon: Icons.share_outlined,
                label: l10n.copieShareCount(state.shareCount),
              ),
            ],
          ),
          if (!hasQuestions) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.copieNeedsQuestion,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          CopieHistory(log: state.log),
        ],
      ),
    );
  }
}
