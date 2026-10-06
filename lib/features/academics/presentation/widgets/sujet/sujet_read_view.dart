import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_cadre_band.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_question_tile.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le sujet en lecture (spec S2) : « Afficher les réponses » et « Modifier »,
/// le bandeau du cadre, puis les questions. Les réponses sont masquées par
/// défaut, et l'état n'est pas mémorisé : il revient masqué.
class SujetReadView extends StatefulWidget {
  final EvaluationSujet sujet;
  final VoidCallback onEdit;

  const SujetReadView({super.key, required this.sujet, required this.onEdit});

  @override
  State<SujetReadView> createState() => _SujetReadViewState();
}

class _SujetReadViewState extends State<SujetReadView> {
  final Set<String> _revealed = {};

  List<String> get _withAnswer => [
    for (final q in widget.sujet.questions)
      if (q.reponseAttendue != null) q.id,
  ];

  bool get _allRevealed =>
      _withAnswer.isNotEmpty && _withAnswer.every(_revealed.contains);

  void _toggleAll() => setState(() {
    if (_allRevealed) {
      _revealed.clear();
    } else {
      _revealed.addAll(_withAnswer);
    }
  });

  void _toggle(String id) => setState(
    () => _revealed.contains(id) ? _revealed.remove(id) : _revealed.add(id),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questions = widget.sujet.questions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (_withAnswer.isNotEmpty)
              TextButton.icon(
                onPressed: _toggleAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bleuArdoise,
                ),
                icon: Icon(
                  _allRevealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                label: Text(
                  _allRevealed ? l10n.sujetHideAnswers : l10n.sujetShowAnswers,
                ),
              ),
            PermissionGate(
              requires: const [Perm.academicsGradeWrite],
              child: SessionWriteGate(
                child: EteeloButton.secondary(
                  label: l10n.sujetEdit,
                  icon: Icons.edit_outlined,
                  fullWidth: false,
                  onPressed: widget.onEdit,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SujetCadreBand(cadre: widget.sujet.cadre),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, q) in questions.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          SujetQuestionTile(
            number: i + 1,
            question: q,
            answerVisible: _revealed.contains(q.id),
            onToggleAnswer: () => _toggle(q.id),
          ),
        ],
      ],
    );
  }
}
