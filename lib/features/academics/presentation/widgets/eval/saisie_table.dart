import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_table_row.dart';

/// Saisie en mode Tableau (spec §8) : une ligne par élève. Détient la chaîne de
/// [FocusNode] pour que « Entrée » passe le focus à l'élève suivant.
class SaisieTable extends StatefulWidget {
  final List<NoteEleve> students;
  final SaisieDraftController draft;
  final bool inputsEnabled;

  const SaisieTable({
    super.key,
    required this.students,
    required this.draft,
    required this.inputsEnabled,
  });

  @override
  State<SaisieTable> createState() => _SaisieTableState();
}

class _SaisieTableState extends State<SaisieTable> {
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.students.length, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant SaisieTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students.length != widget.students.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = List.generate(widget.students.length, (_) => FocusNode());
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _focusNext(int index) {
    if (index + 1 < _nodes.length) {
      _nodes[index + 1].requestFocus();
    } else {
      _nodes[index].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Column(
          children: [
            for (var i = 0; i < widget.students.length; i++)
              SaisieTableRow(
                key: ValueKey<String>('row-${widget.students[i].studentId}'),
                position: i + 1,
                student: widget.students[i],
                draft: widget.draft,
                focusNode: _nodes[i],
                inputsEnabled: widget.inputsEnabled,
                onSubmitted: () => _focusNext(i),
              ),
          ],
        ),
      ),
    );
  }
}
