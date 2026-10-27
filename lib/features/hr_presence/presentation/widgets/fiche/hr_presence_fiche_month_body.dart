import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_month_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_day_sheet.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/hr_register_location.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le corps mensuel de la fiche d'un agent : le calendrier, dont un jour
/// passé ouvre la feuille du jour, et l'annonce des jours corrigés sur la
/// tablette que le serveur n'a pas encore reçus.
class HrPresenceFicheMonthBody extends StatelessWidget {
  final HrAttendanceAgentMonth month;
  final HrPresenceFicheState state;
  final HrPresenceFicheCubit cubit;

  const HrPresenceFicheMonthBody({
    super.key,
    required this.month,
    required this.state,
    required this.cubit,
  });

  Future<void> _openDay(BuildContext context, String day) async {
    HrAttendanceDay? server;
    for (final candidate in month.days) {
      if (candidate.date == day) server = candidate;
    }
    if (server == null || server.future) return;
    final edit = await showHrPresenceDaySheet(
      context,
      agent: month.agent,
      server: server,
      // Le registre de ce jour, dans la coquille et par son adresse : la
      // fiche, poussée par-dessus, n'en voit pas la navigation.
      onOpenRegister: () {
        if (!context.mounted) return;
        context.go(
          Uri(
            path: AppRoutesNames.homeSubMenuPath(
              MenuConstants.hrPresenceRegisterId,
            ),
            queryParameters: {HrRegisterLocation.dayParam: day},
          ).toString(),
        );
      },
    );
    if (edit != null && !cubit.isClosed) cubit.noteLocalDay(day, edit.record);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = state.localDays.keys
        .where((day) => SchoolDayCalendar.monthOf(day) == month.month)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending > 0) ...[
          PresenceWarning(
            message: l10n.hrPresenceDayPendingNotice(pending),
            icon: Icons.cloud_upload_outlined,
            tone: PresenceStatus.none,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        HrPresenceMonthBody(
          month: month,
          withTrend: false,
          localDays: state.localDays,
          onTapDay: (day) => unawaited(_openDay(context, day)),
        ),
      ],
    );
  }
}
