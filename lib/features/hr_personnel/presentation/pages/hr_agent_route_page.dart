import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// La fiche d'un agent ouverte par son adresse (`/home/{sousMenu}/{agentId}`).
///
/// L'agent est **toujours relu** dans le fichier local, même ouvert depuis la
/// liste : Suivant du navigateur rejoue la navigation, et un agent passé à
/// l'ouverture reviendrait tel qu'il était. Un agent absent fait tirer les
/// flux une fois avant de se dire introuvable — une tablette neuve n'a
/// peut-être pas encore descendu le fichier ; hors ligne, c'est le réseau qui
/// manque, et la page le dit.
class HrAgentRoutePage extends StatefulWidget {
  final String subMenuId;
  final String agentId;

  /// Prévient l'écran qui a ouvert la fiche, à sa disparition.
  final VoidCallback? onClosed;
  final DateTime Function() now;

  const HrAgentRoutePage({
    super.key,
    required this.subMenuId,
    required this.agentId,
    this.onClosed,
    this.now = DateTime.now,
  });

  @override
  State<HrAgentRoutePage> createState() => _HrAgentRoutePageState();
}

enum _Lookup { loading, found, missing, failure }

/// L'agent relu, son contrat du jour, et le reste du fichier pour les
/// doublons.
typedef _Agent = ({
  StaffMember member,
  StaffContractKind? kind,
  List<StaffMember> others,
  String today,
});

class _HrAgentRoutePageState extends State<HrAgentRoutePage> {
  late final StaffSnapshotSource _source = getIt<StaffSnapshotSource>();
  _Lookup _lookup = _Lookup.loading;
  _Agent? _agent;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void dispose() {
    widget.onClosed?.call();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (_lookup != _Lookup.loading) setState(() => _lookup = _Lookup.loading);
    if (await _read()) return;
    await _source.pull();
    if (!mounted) return;
    if (await _read()) return;
    final online = await getIt<ConnectivityService>().isOnline();
    if (!mounted) return;
    setState(() {
      if (online) {
        _lookup = _Lookup.missing;
      } else {
        _failure = const NetworkFailure('Aucune connexion.');
        _lookup = _Lookup.failure;
      }
    });
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
        final agent = _agentFrom(snapshot);
        if (agent == null) return false;
        setState(() {
          _agent = agent;
          _lookup = _Lookup.found;
        });
        return true;
      },
    );
  }

  _Agent? _agentFrom(StaffFileSnapshot snapshot) {
    final member = snapshot.members
        .where((m) => m.id == widget.agentId)
        .firstOrNull;
    if (member == null) return null;
    final today = HrPersonnelCubit.dayOf(widget.now());
    return (
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
    final agent = _agent;
    if (_lookup == _Lookup.found && agent != null) {
      return StaffAgentPage(
        member: agent.member,
        kind: agent.kind,
        others: agent.others,
        today: agent.today,
      );
    }

    final l10n = AppLocalizations.of(context)!;
    // La sortie reste offerte pendant la lecture et le tirage.
    final bar = OffShellTopBar(
      eyebrow: l10n.hrPersonnelEyebrow,
      title: widget.subMenuId == MenuConstants.hrPersonnelDashboardId
          ? l10n.subMenuDashboard
          : l10n.subMenuHrPersonnelFile,
      backTooltip: l10n.staffActionBack,
      shellSubMenuId: widget.subMenuId,
    );
    return AppPageBackground(
      appBar: bar,
      scrollable: _lookup != _Lookup.loading,
      child: switch (_lookup) {
        _Lookup.loading ||
        _Lookup.found => const EteeloListSkeleton(rowCount: 4),
        _Lookup.failure => StaffResultsErrorState(
          failure: _failure,
          onRetry: () => unawaited(_resolve()),
        ),
        _Lookup.missing => EteeloEmptyResult(
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
      },
    );
  }
}
