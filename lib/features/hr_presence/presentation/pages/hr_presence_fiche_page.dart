import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profiles_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/hr_fiche_location.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Fiche individuelle — le profil de présence de chaque
/// agent, sur le mois ou l'année, **en ligne** (route 4).
class HrPresenceFichePage extends StatelessWidget {
  const HrPresenceFichePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => getIt<HrPresenceProfilesCubit>(
      param1: HrPresenceContext.yearStart(context),
    )..load(),
    child: HrPresenceFicheScreen(
      onOpenAgent: (context, row) {
        final state = context.read<HrPresenceProfilesCubit>().state;
        unawaited(
          HrPresenceFicheAgentPage.open(
            context,
            agentId: row.agent.staffMemberId,
            yearly: state.yearly,
            month: state.month,
          ),
        );
      },
    ),
  );
}

class HrPresenceFicheScreen extends StatelessWidget {
  /// `null` : les lignes ne s'ouvrent pas.
  final void Function(BuildContext context, HrAttendanceProfileRow row)?
  onOpenAgent;

  const HrPresenceFicheScreen({super.key, this.onOpenAgent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceProfilesCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.retry()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPresenceEyebrow,
                title: l10n.subMenuHrPresenceFiche,
              ),
        child: BlocBuilder<HrPresenceProfilesCubit, HrPresenceProfilesState>(
          builder: (context, state) => HrFicheLocation(
            state: state,
            cubit: cubit,
            child: HrPresenceProfilesBody(
              state: state,
              onOpen: (row) => onOpenAgent?.call(context, row),
            ),
          ),
        ),
      ),
    );
  }
}
