import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre les retours du [ProgrammeCubit] (créé, mis à jour, supprimé,
/// ressource non gardée, échec d'écriture), une fois chacun.
///
/// Posé sur la page du programme **et** sur celle d'un chapitre : modifier
/// un chapitre depuis son détail émet sur le cubit du programme, dont la page
/// n'est alors plus montée.
class ProgrammeFeedbackListener extends StatelessWidget {
  final Widget child;

  const ProgrammeFeedbackListener({super.key, required this.child});

  static void _show(BuildContext context, ProgrammeState state) {
    final l10n = AppLocalizations.of(context)!;
    final titre = state.feedback?.titre ?? '';
    switch (state.feedback?.kind) {
      case ProgrammeFeedbackKind.chapitreCreated:
        AppSnackBar.showSuccess(context, l10n.programmeChapitreCreated(titre));
      case ProgrammeFeedbackKind.chapitreUpdated:
        AppSnackBar.showSuccess(context, l10n.programmeChapitreUpdated(titre));
      case ProgrammeFeedbackKind.chapitreDeleted:
        AppSnackBar.showSuccess(context, l10n.programmeChapitreDeleted);
      case ProgrammeFeedbackKind.ressourceKeepFailed:
        AppSnackBar.showError(context, l10n.ressourceKeepFailed);
      case ProgrammeFeedbackKind.writeFailed:
        AppSnackBar.showError(context, l10n.programmeWriteFailed);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ProgrammeCubit, ProgrammeState>(
        listenWhen: (prev, curr) =>
            curr.feedback != null && prev.feedback != curr.feedback,
        listener: _show,
        child: child,
      );
}
