import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_section_card.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Sujet » du détail (spec S2) : pliable, avec son résumé et la
/// pastille du barème quand il n'est pas complet. Ouverte d'office si
/// [initiallyExpanded] ; jamais pliable pendant l'édition ([editor]).
class SujetSection extends StatefulWidget {
  final EvaluationSujet sujet;
  final double maxPoints;
  final bool initiallyExpanded;
  final VoidCallback onEdit;

  /// L'éditeur en cours, à la place de la lecture.
  final Widget? editor;

  /// Vue de lecture d'un sujet non vide.
  final Widget Function() readView;

  /// Avis posé au-dessus du contenu (refus du serveur).
  final Widget? notice;

  const SujetSection({
    super.key,
    required this.sujet,
    required this.maxPoints,
    required this.initiallyExpanded,
    required this.onEdit,
    required this.readView,
    this.editor,
    this.notice,
  });

  @override
  State<SujetSection> createState() => _SujetSectionState();
}

class _SujetSectionState extends State<SujetSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sujet = widget.sujet;
    final editing = widget.editor != null;
    final bareme = SujetBareme(
      total: sujet.totalPoints,
      maxPoints: widget.maxPoints,
    );
    final status = bareme.status;
    final visual = baremeVisual(status);
    return EvalSectionCard(
      title: l10n.sujetSectionTitle,
      subtitle: sujetSummary(
        l10n,
        questionCount: sujet.questions.length,
        bareme: bareme,
        dureeMinutes: sujet.cadre.dureeMinutes,
      ),
      trailing: [
        if (!sujet.isEmpty && status != BaremeStatus.complete)
          NotationPill(
            color: visual.color,
            soft: visual.soft,
            icon: visual.icon,
            label: baremeMessage(l10n, bareme),
          ),
      ],
      expanded: editing || _expanded,
      onToggle: editing ? null : () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.notice != null) ...[
            widget.notice!,
            const SizedBox(height: AppSpacing.md),
          ],
          widget.editor ?? (sujet.isEmpty ? _empty(l10n) : widget.readView()),
        ],
      ),
    );
  }

  Widget _empty(AppLocalizations l10n) => EteeloEmptyResult(
    label: l10n.sujetEmptyTitle,
    description: l10n.sujetEmptyDescription,
    medallionIcon: Icons.list_alt_rounded,
    primaryAction: PermissionGate(
      requires: const [Perm.academicsGradeWrite],
      child: EteeloButton.primary(
        label: l10n.sujetEmptyAction,
        icon: Icons.edit_outlined,
        fullWidth: false,
        onPressed: widget.onEdit,
      ),
    ),
  );
}
