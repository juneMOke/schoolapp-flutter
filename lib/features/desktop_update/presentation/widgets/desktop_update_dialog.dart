import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_cubit.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_state.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/widgets/desktop_update_dialog_body.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fenêtre de mise à jour : une seule, qui suit le cubit d'étape en étape
/// (proposition, outbox, téléchargement, installation, échec). Elle se ferme
/// d'elle-même quand le cubit ne la veut plus (« Plus tard », annulation).
///
/// Ni la touche Échap ni un clic à côté ne la ferment : une mise à jour
/// obligatoire n'a pas d'issue, une facultative a son « Plus tard ».
class DesktopUpdateDialog extends StatelessWidget {
  final void Function() onQuit;

  const DesktopUpdateDialog({super.key, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<DesktopUpdateCubit, DesktopUpdateState>(
      listenWhen: (previous, current) =>
          previous.wantsDialog && !current.wantsDialog,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) {
        final cubit = context.read<DesktopUpdateCubit>();
        final offer = state.offer;
        if (offer == null) return const SizedBox.shrink();
        final version = '${offer.release.version}';
        return PopScope(
          canPop: false,
          child: EteeloCardDialog(
            eyebrow: l10n.desktopUpdateEyebrow,
            title: state.mandatory
                ? l10n.desktopUpdateMandatoryTitle
                : l10n.desktopUpdateAvailableTitle(version),
            // La croix vaut « Plus tard », sans effet quand c'est obligatoire
            // ou qu'un geste est en cours.
            onClose: cubit.later,
            onSubmit: state.status == DesktopUpdateStatus.available
                ? cubit.update
                : null,
            body: DesktopUpdateDialogBody(state: state),
            actions: _actions(l10n, state, cubit),
          ),
        );
      },
    );
  }

  List<Widget> _actions(
    AppLocalizations l10n,
    DesktopUpdateState state,
    DesktopUpdateCubit cubit,
  ) => switch (state.status) {
    DesktopUpdateStatus.available || DesktopUpdateStatus.idle => [
      if (state.mandatory)
        EteeloButton.ghost(label: l10n.desktopUpdateQuit, onPressed: onQuit)
      else
        EteeloButton.ghost(
          label: l10n.desktopUpdateLater,
          onPressed: cubit.later,
        ),
      EteeloButton.primary(
        label: l10n.desktopUpdateNow,
        icon: Icons.system_update_alt_rounded,
        onPressed: cubit.update,
      ),
    ],
    DesktopUpdateStatus.confirmPending => [
      EteeloButton.ghost(
        label: l10n.desktopUpdateCancel,
        onPressed: cubit.cancel,
      ),
      EteeloButton.primary(
        label: l10n.desktopUpdateContinue,
        onPressed: cubit.continueDespitePending,
      ),
    ],
    DesktopUpdateStatus.downloading => [
      EteeloButton.ghost(
        label: l10n.desktopUpdateCancel,
        onPressed: cubit.cancel,
      ),
    ],
    DesktopUpdateStatus.failed => [
      if (state.mandatory)
        EteeloButton.ghost(label: l10n.desktopUpdateQuit, onPressed: onQuit)
      else
        EteeloButton.ghost(
          label: l10n.desktopUpdateClose,
          onPressed: cubit.cancel,
        ),
      EteeloButton.primary(
        label: l10n.desktopUpdateRetry,
        onPressed: cubit.update,
      ),
    ],
    DesktopUpdateStatus.preparing || DesktopUpdateStatus.installing => const [],
  };
}
