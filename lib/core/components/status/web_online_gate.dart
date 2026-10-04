import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/web/unload_guard.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La version web est EN LIGNE SEULEMENT : sans réseau, l'application se voile
/// d'un écran « Connexion requise », et reprend d'elle-même au retour.
///
/// Le voile recouvre l'application sans la démonter : un formulaire en cours
/// de saisie survit à une coupure.
///
/// Tant qu'un envoi attend dans l'outbox, fermer ou recharger l'onglet demande
/// confirmation — l'outbox survit dans IndexedDB, mais un encaissement ne doit
/// pas dormir dans un navigateur qu'on a refermé.
///
/// Transparent hors du web.
class WebOnlineGate extends StatefulWidget {
  final Widget child;
  final ConnectivityService connectivity;
  final bool enabled;
  final void Function(bool active) onUnloadGuardChanged;

  const WebOnlineGate({
    super.key,
    required this.child,
    required this.connectivity,
    this.enabled = kIsWeb,
    this.onUnloadGuardChanged = setUnloadGuard,
  });

  /// Du travail non envoyé — ou dont on ne peut rien dire, hors ligne.
  static bool hasUnsentWork(SyncStatusState state) => switch (state.status) {
    SyncStatus.pendingUpload ||
    SyncStatus.syncing ||
    SyncStatus.syncConflict ||
    SyncStatus.offline => true,
    SyncStatus.synced ||
    SyncStatus.partiallySynced ||
    SyncStatus.authRequired => state.hasHeldWork,
  };

  @override
  State<WebOnlineGate> createState() => _WebOnlineGateState();
}

class _WebOnlineGateState extends State<WebOnlineGate> {
  bool _online = true;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    _subscription = widget.connectivity.onStatusChange.listen(_setOnline);
    unawaited(widget.connectivity.isOnline().then(_setOnline));
    widget.onUnloadGuardChanged(
      WebOnlineGate.hasUnsentWork(context.read<SyncStatusCubit>().state),
    );
  }

  void _setOnline(bool online) {
    if (!mounted || online == _online) return;
    setState(() => _online = online);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    if (widget.enabled) widget.onUnloadGuardChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<SyncStatusCubit, SyncStatusState>(
      listenWhen: (previous, current) =>
          WebOnlineGate.hasUnsentWork(previous) !=
          WebOnlineGate.hasUnsentWork(current),
      listener: (_, state) =>
          widget.onUnloadGuardChanged(WebOnlineGate.hasUnsentWork(state)),
      child: Stack(
        children: [
          ExcludeFocus(excluding: !_online, child: widget.child),
          if (!_online)
            Positioned.fill(
              child: Material(
                color: AppColors.surfaceDark,
                child: SafeArea(
                  child: EteeloErrorResult(
                    type: EteeloErrorType.network,
                    fullWidthCard: false,
                    title: l10n.webOfflineTitle,
                    message: l10n.webOfflineMessage,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
