import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_dialog.dart';

/// Crée ([chapitre] `null`) ou modifie un chapitre : charge sa fiche entière
/// (la liste ne porte pas ses ressources), ouvre la modale, puis enregistre
/// l'édition par le [ProgrammeCubit] de l'arbre.
Future<void> openChapitreForm(
  BuildContext context, {
  required CoursDetailArgs cours,
  Chapitre? chapitre,
}) async {
  final cubit = context.read<ProgrammeCubit>();
  var base = chapitre;
  if (chapitre != null) {
    base = await cubit.chapitreForEdit(chapitre.id);
    if (!context.mounted || base == null) return;
  }
  final edit = await showChapitreFormDialog(
    context,
    cours: cours,
    chapitre: base,
    sousPeriodes: cubit.state.sousPeriodes,
    newId: cubit.newId,
  );
  if (edit == null || !context.mounted) return;
  await cubit.saveEdit(edit);
}
