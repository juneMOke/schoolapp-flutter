import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Récapitulatif — les totaux du mois par agent, lus au
/// serveur (route 5), et la clôture du mois. Le mois tient dans l'adresse
/// (`?mois=AAAA-MM`, nue sur le mois en cours).
class HrPresenceRecapPage extends StatelessWidget {
  static const monthParam = 'mois';

  const HrPresenceRecapPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => getIt<HrPresenceRecapCubit>(
      param1: HrPresenceContext.yearStart(context),
    )..load(),
    child: HrPresenceRecapScreen(
      // La fiche individuelle de l'agent, vue mensuelle sur ce mois.
      onOpenAgent: (context, row) => unawaited(
        HrPresenceFicheAgentPage.open(
          context,
          agentId: row.agent.staffMemberId,
          yearly: false,
          month: context.read<HrPresenceRecapCubit>().state.month,
          fromSubMenuId: MenuConstants.hrPresenceRecapId,
        ),
      ),
    ),
  );
}

class HrPresenceRecapScreen extends StatelessWidget {
  final void Function(BuildContext context, HrAttendanceRecapRow row)?
  onOpenAgent;

  const HrPresenceRecapScreen({super.key, this.onOpenAgent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceRecapCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.retry()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPresenceEyebrow,
                title: l10n.subMenuHrPresenceRecap,
              ),
        child: BlocBuilder<HrPresenceRecapCubit, HrPresenceRecapState>(
          builder: (context, state) => LocationParamsSync(
            current: {
              HrPresenceRecapPage.monthParam: state.isCurrentMonth
                  ? null
                  : state.month,
            },
            onLocation: (values) => unawaited(
              cubit.applyLocation(values[HrPresenceRecapPage.monthParam]),
            ),
            child: HrPresenceRecapBody(
              state: state,
              onOpen: (row) => onOpenAgent?.call(context, row),
            ),
          ),
        ),
      ),
    );
  }
}
