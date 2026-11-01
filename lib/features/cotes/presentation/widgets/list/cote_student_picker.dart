import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste des élèves quand la grille prend toute la largeur : un sélecteur
/// « 01 · Nom — 21/24 ».
class CoteStudentPicker extends StatelessWidget {
  final VoidCallback? onStudentChanged;

  const CoteStudentPicker({super.key, this.onStudentChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
      buildWhen: (previous, current) =>
          current is CoteSaisieReady &&
          (previous is! CoteSaisieReady ||
              previous.currentId != current.currentId ||
              previous.calcs != current.calcs),
      builder: (context, state) {
        if (state is! CoteSaisieReady) return const SizedBox.shrink();
        return EteeloSelectInput<String>(
          label: l10n.cotePickerSemantics,
          hideLabel: true,
          value: state.currentId,
          minWidth: 0,
          searchable: true,
          onChanged: (id) {
            if (id == null || id == state.currentId) return;
            context.read<CoteSaisieBloc>().add(CoteStudentSelected(id));
            onStudentChanged?.call();
          },
          items: [
            for (final (index, eleve) in state.eleves.indexed)
              EteeloSelectItem<String>(
                value: eleve.studentId,
                label: l10n.cotePickerItem(
                  '${index + 1}'.padLeft(2, '0'),
                  eleve.fullName,
                  state.calcs[eleve.studentId]?.filled ?? 0,
                  state.calcs[eleve.studentId]?.cells ?? 0,
                ),
              ),
          ],
        );
      },
    );
  }
}
