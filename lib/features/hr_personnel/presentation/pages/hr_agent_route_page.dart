import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche d'un agent ouverte par son adresse (`/home/{sousMenu}/{agentId}`).
///
/// Ouverte depuis la liste, elle reçoit l'agent ([intent]) et s'affiche
/// aussitôt. Rechargée, collée ou partagée, elle relit le fichier local ; un
/// agent absent fait tirer les flux une fois avant de se dire introuvable —
/// une tablette neuve n'a peut-être pas encore descendu le fichier.
class HrAgentRoutePage extends StatefulWidget {
  final String subMenuId;
  final String agentId;
  final HrAgentIntent? intent;
  final DateTime Function() now;

  const HrAgentRoutePage({
    super.key,
    required this.subMenuId,
    required this.agentId,
    this.intent,
    this.now = DateTime.now,
  });

  @override
  State<HrAgentRoutePage> createState() => _HrAgentRoutePageState();
}

enum _Lookup { loading, found, missing, failure }

class _HrAgentRoutePageState extends State<HrAgentRoutePage> {
  late final StaffSnapshotSource _source = getIt<StaffSnapshotSource>();
  _Lookup _lookup = _Lookup.loading;
  HrAgentIntent? _intent;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _intent = widget.intent;
    if (_intent != null) {
      _lookup = _Lookup.found;
    } else {
      unawaited(_resolve());
    }
  }

  @override
  void dispose() {
    widget.intent?.onClosed?.call();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (_lookup != _Lookup.loading) setState(() => _lookup = _Lookup.loading);
    if (await _read()) return;
    await _source.pull();
    if (!mounted) return;
    if (await _read()) return;
    if (mounted) setState(() => _lookup = _Lookup.missing);
  }

  /// Vrai quand la lecture a tranché (agent trouvé, ou base illisible).
  Future<bool> _read() async {
    final result = await _source.read();
    if (!mounted) return true;
    return result.fold(
      (failure) {
        setState(() {
          _failure = failure;
          _lookup = _Lookup.failure;
        });
        return true;
      },
      (snapshot) {
        final intent = _intentFrom(snapshot);
        if (intent == null) return false;
        setState(() {
          _intent = intent;
          _lookup = _Lookup.found;
        });
        return true;
      },
    );
  }

  HrAgentIntent? _intentFrom(StaffFileSnapshot snapshot) {
    final member = snapshot.members
        .where((m) => m.id == widget.agentId)
        .firstOrNull;
    if (member == null) return null;
    final today = HrPersonnelCubit.dayOf(widget.now());
    return HrAgentIntent(
      member: member,
      kind: StaffContractTimeline.currentAt(member.contracts, today)?.kind,
      others: snapshot.members,
      today: today,
    );
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutesNames.homeSubMenuPath(widget.subMenuId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final intent = _intent;
    if (_lookup == _Lookup.found && intent != null) {
      return StaffAgentPage(
        member: intent.member,
        kind: intent.kind,
        others: intent.others,
        today: intent.today,
      );
    }
    if (_lookup == _Lookup.loading) {
      return const AppPageBackground(
        scrollable: false,
        child: EteeloListSkeleton(rowCount: 4),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return AppPageBackground(
      appBar: OffShellTopBar(
        eyebrow: l10n.hrPersonnelEyebrow,
        title: widget.subMenuId == MenuConstants.hrPersonnelDashboardId
            ? l10n.subMenuDashboard
            : l10n.subMenuHrPersonnelFile,
        backTooltip: l10n.staffActionBack,
        shellSubMenuId: widget.subMenuId,
      ),
      child: _lookup == _Lookup.failure
          ? StaffResultsErrorState(
              failure: _failure,
              onRetry: () => unawaited(_resolve()),
            )
          : EteeloEmptyResult(
              label: l10n.hrAgentNotFoundTitle,
              description: l10n.hrAgentNotFoundMessage,
              medallionIcon: Icons.person_search_outlined,
              fullWidthCard: true,
              primaryAction: EteeloButton.primary(
                label: l10n.hrAgentNotFoundAction,
                icon: Icons.arrow_back,
                onPressed: _leave,
                fullWidth: false,
              ),
            ),
    );
  }
}
