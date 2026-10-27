import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/services/hr_presence_day_check.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_day_read_only.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la feuille du jour a écrit : la ligne de la tablette après le
/// dernier geste (`null` : remise « à pointer »).
typedef HrPresenceDayEdit = ({StaffAttendanceRecord? record});

/// La feuille du jour d'un agent, ouverte depuis le calendrier de sa fiche :
/// le jour tel que la fiche le montre, et — quand c'est sûr — **la carte du
/// registre**, mêmes gestes, mêmes règles, même file d'envoi.
///
/// La fiche lit le serveur, l'écriture part de la tablette : la feuille relit
/// le jour (le registre de la tablette, puis un pull), et ne propose la carte
/// que si la tablette dit la même chose que le serveur, ou plus récent
/// ([HrPresenceDayCheck]). Sinon — jour absent ou divergent, rapport validé,
/// mois clos, compte sans droit d'écriture — elle se lit seulement, et
/// renvoie au registre quand il peut aider.
///
/// Rend la ligne écrite si un geste a eu lieu, sinon `null`.
Future<HrPresenceDayEdit?> showHrPresenceDaySheet(
  BuildContext context, {
  required HrAttendanceAgent agent,
  required HrAttendanceDay server,
  required VoidCallback onOpenRegister,
  StaffAttendanceCubit Function()? createCubit,
}) async {
  final outcome = _Outcome();
  await showEteeloAdaptiveSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<StaffAttendanceCubit>(
      create: (_) {
        final cubit = createCubit?.call() ?? getIt<StaffAttendanceCubit>();
        unawaited(
          cubit.load().then((_) {
            if (!cubit.isClosed) return cubit.showDay(server.date);
          }),
        );
        return cubit;
      },
      child: _HrPresenceDaySheet(
        agent: agent,
        server: server,
        outcome: outcome,
        onOpenRegister: () {
          Navigator.of(sheetContext).pop();
          onOpenRegister();
        },
      ),
    ),
  );
  return outcome.edited ? (record: outcome.record) : null;
}

/// La dernière ligne écrite, gardée hors de la feuille : elle se referme
/// aussi par la barrière ou le retour, qui ne rendent rien.
class _Outcome {
  bool edited = false;
  StaffAttendanceRecord? record;

  /// La ligne de la tablette à l'ouverture : un geste qui n'a rien changé ne
  /// rend rien.
  bool _seen = false;
  StaffAttendanceRecord? _initial;

  void observe(StaffDayRow? row, {required bool touched}) {
    if (row == null) return;
    if (!_seen) {
      _seen = true;
      _initial = row.record;
    }
    if (touched && row.record != _initial) {
      edited = true;
      record = row.record;
    }
  }
}

class _HrPresenceDaySheet extends StatelessWidget {
  final HrAttendanceAgent agent;
  final HrAttendanceDay server;
  final VoidCallback onOpenRegister;
  final _Outcome outcome;

  const _HrPresenceDaySheet({
    required this.agent,
    required this.server,
    required this.onOpenRegister,
    required this.outcome,
  });

  /// La ligne de l'agent dans le registre de la tablette, une fois le bon
  /// jour lu ; `null` tant qu'il ne l'est pas, ou si l'agent n'y est pas.
  StaffDayRow? _rowOf(StaffAttendanceState state) {
    if (state.day != server.date) return null;
    for (final row in state.register.all) {
      if (row.member.id == agent.staffMemberId) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hrPresenceDaySheetTitle(
                        PresenceLabels.longDay(dates, server.date),
                      ),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      HrPresenceLabels.fullName(agent),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: AppDimensions.presenceMarkTapTarget,
                child: IconButton(
                  tooltip: dates.closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BlocListener<StaffAttendanceCubit, StaffAttendanceState>(
            listenWhen: (previous, current) =>
                current.notice != null && previous.notice != current.notice,
            listener: (context, state) =>
                showStaffAttendanceNotice(context, state.notice!),
            child: BlocConsumer<StaffAttendanceCubit, StaffAttendanceState>(
              // La ligne de la tablette après le dernier geste de la feuille.
              listener: (context, state) => outcome.observe(
                _rowOf(state),
                touched: context.read<StaffAttendanceCubit>().shownDayEdited,
              ),
              buildWhen: (previous, current) =>
                  previous.copyWith(notice: current.notice) != current,
              builder: (context, state) => _content(context, l10n, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    StaffAttendanceState state,
  ) {
    final cubit = context.read<StaffAttendanceCubit>();
    final row = _rowOf(state);
    Widget readOnly(String message, {bool register = false}) =>
        HrPresenceDayReadOnly(
          server: server,
          message: message,
          onOpenRegister: register ? onOpenRegister : null,
        );
    if (state.load == StaffAttendanceLoad.failure) {
      return StaffResultsErrorState(
        failure: state.failure,
        onRetry: () => unawaited(cubit.load()),
      );
    }
    if (!PermissionGate.allowsAccess(context, kStaffAttendanceWriteAccess)) {
      return readOnly(l10n.hrPresenceDayReadOnlyRight);
    }
    if (state.load == StaffAttendanceLoad.loading || state.day != server.date) {
      return EteeloListSkeleton(
        rowCount: 1,
        semanticsLabel: l10n.hrPresenceDayLoading,
      );
    }
    final snapshot = state.snapshot;
    if (snapshot.isMonthClosed(SchoolDayCalendar.monthOf(server.date))) {
      return readOnly(l10n.hrPresenceDayMonthClosed);
    }
    if (snapshot.isDayValidated(server.date)) {
      return readOnly(l10n.hrPresenceDayValidated, register: true);
    }
    final agreement = row == null
        ? HrPresenceDayAgreement.missing
        : HrPresenceDayCheck.of(server: server, local: row.record);
    // Une fois corrigé ici, le jour reste ouvert : la ligne de la tablette
    // est alors la plus récente, quoi que dise encore la fiche.
    if (row == null || (!agreement.editable && !cubit.shownDayEdited)) {
      return readOnly(
        agreement == HrPresenceDayAgreement.divergent
            ? l10n.hrPresenceDayDivergent
            : l10n.hrPresenceDayMissing,
        register: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffAttendanceCard(
          row: row,
          settings: snapshot.settings,
          frozen: state.register.frozen,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.hrPresenceDaySheetSaved,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
