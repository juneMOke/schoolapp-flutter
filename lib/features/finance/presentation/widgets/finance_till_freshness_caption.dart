import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/last_sync_label.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// De quand datent les chiffres du tiroir.
///
/// **Le seul écran du projet qu'on compare à des billets**, et le seul dont le
/// total puisse être en dessous de la vérité sans que rien ne le signale :
/// encaissements et ventes boutique passent tous deux par la file d'écritures,
/// et le serveur ne totalise que ce qui lui est parvenu. Hors ligne, ou file
/// non vidée à la fermeture, l'écran sous-compte.
///
/// La ligne ne prétend pas corriger l'écart — elle le date. « Arrêté à la
/// dernière synchro · Il y a 1 h » suffit à faire regarder la pastille de la
/// barre supérieure, qui, elle, porte l'état de la file.
///
/// ⚠️ `lastSyncAtMs` date le **pull**, pas le push : un envoi réussi il y a deux
/// minutes peut coexister avec « Il y a 3 h ». L'écart va dans le sens prudent
/// — la ligne annonce des chiffres plus vieux qu'ils ne sont, jamais plus
/// frais — et c'est la raison de ne pas inventer une seconde estampille tant
/// que personne ne s'en plaint.
class FinanceTillFreshnessCaption extends StatelessWidget {
  const FinanceTillFreshnessCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      buildWhen: (prev, curr) => prev.lastSyncAtMs != curr.lastSyncAtMs,
      builder: (context, state) {
        final relative = relativeLastSyncLabel(l10n, state.lastSyncAtMs);
        final label = relative == null
            ? l10n.financeTillFreshnessNever
            : l10n.financeTillFreshnessNotice(relative);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 13,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
