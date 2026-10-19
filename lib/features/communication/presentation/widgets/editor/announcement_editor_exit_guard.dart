import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/bloc_exit_guard.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Garde la rédaction d'un communiqué : le brouillon ne s'enregistre que par
/// un geste, et quitter l'éditeur (Précédent, F5, autre écran du menu) le
/// perdrait sans un mot.
///
/// La saisie se juge contre le contenu à l'ouverture : un communiqué rouvert
/// sans y toucher se quitte librement.
class AnnouncementEditorExitGuard extends StatefulWidget {
  final Widget child;

  const AnnouncementEditorExitGuard({super.key, required this.child});

  @override
  State<AnnouncementEditorExitGuard> createState() =>
      _AnnouncementEditorExitGuardState();
}

class _AnnouncementEditorExitGuardState
    extends State<AnnouncementEditorExitGuard> {
  late final AnnouncementContent _opened = context
      .read<AnnouncementEditorCubit>()
      .state
      .content;

  @override
  Widget build(BuildContext context) =>
      BlocExitGuard<AnnouncementEditorCubit, AnnouncementEditorState>(
        hasUnsavedWork: (state) =>
            !state.isLocked &&
            state.outcome == null &&
            state.content != _opened,
        isBusy: (state) => state.busy != null,
        discardMessage: AppLocalizations.of(
          context,
        )!.communicationEditorDiscardMessage,
        child: widget.child,
      );
}
