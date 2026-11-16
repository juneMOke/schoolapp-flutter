import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/online_only.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/closing_actions.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_screen.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trésorerie ▸ Clôture de caisse.
class CashClosingPage extends StatefulWidget {
  const CashClosingPage({super.key});

  @override
  State<CashClosingPage> createState() => _CashClosingPageState();
}

class _CashClosingPageState extends State<CashClosingPage> {
  /// L'écran relit ce qu'il affiche (journée, semaine ou mois) quand on tire
  /// la page.
  final _screen = GlobalKey<ClosingScreenState>();

  @override
  Widget build(BuildContext context) => BlocProvider<CashClosingCubit>(
    // L'écran lance la première lecture, sur la journée de l'adresse.
    create: (_) => GetIt.instance<CashClosingCubit>(),
    child: TreasuryRefreshScope(
      keyboard: false,
      onRefresh: () async => _screen.currentState?.refresh(),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        scrollable: true,
        child: _ClosingBody(screenKey: _screen),
      ),
    ),
  );
}

class _ClosingBody extends StatelessWidget {
  final GlobalKey<ClosingScreenState> screenKey;

  const _ClosingBody({required this.screenKey});

  @override
  Widget build(BuildContext context) {
    final actions = ClosingActions(
      context,
      context.read<CashClosingCubit>(),
      GetIt.instance<IdGenerator>(),
    );
    // Le serveur vérifie les droits ; l'écran ne fait que masquer les gestes.
    final canClose = PermissionGate.allowsAccess(context, kTreasuryCloseAccess);
    final canWrite = PermissionGate.allowsAccess(
      context,
      kTreasuryRegisterWriteAccess,
    );
    final screen = OnlineOnly(
      builder: (context, online) => _RefreshOnReconnect(
        online: online,
        child: ClosingScreen(
          key: screenKey,
          online: online,
          callbacks: ClosingCallbacks(
            close: canClose ? actions.close : null,
            answer: canClose ? actions.answer : null,
            reopen: canWrite ? actions.reopen : null,
            configure: canWrite ? () => _openConfiguration(context) : null,
          ),
        ),
      ),
    );
    final sync = _syncStatusOf(context);
    if (sync == null) return screen;
    // La file d'envoi vidée, le compteur « pas encore envoyés » tombe : on
    // relit, sinon le bouton resterait bloqué jusqu'au prochain changement
    // de jour.
    return BlocListener<SyncStatusCubit, SyncStatusState>(
      bloc: sync,
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SyncStatus.synced,
      listener: (context, _) => context.read<CashClosingCubit>().refresh(),
      child: screen,
    );
  }

  /// Le cubit global de synchronisation, absent dans les tests d'écran.
  static SyncStatusCubit? _syncStatusOf(BuildContext context) {
    try {
      return context.read<SyncStatusCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  static void _openConfiguration(BuildContext context) =>
      context.read<NavigationBloc>().add(
        SubMenuItemSelected(
          menuId: MenuConstants.treasuryMenuId,
          subMenuId: MenuConstants.treasuryConfigId,
          title: AppLocalizations.of(context)!.subMenuTreasuryConfig,
        ),
      );
}

/// Relit la journée quand la tablette revient en ligne : hors ligne, la
/// journée affichée et ses envois en attente datent du dernier chargement.
class _RefreshOnReconnect extends StatefulWidget {
  final bool online;
  final Widget child;

  const _RefreshOnReconnect({required this.online, required this.child});

  @override
  State<_RefreshOnReconnect> createState() => _RefreshOnReconnectState();
}

class _RefreshOnReconnectState extends State<_RefreshOnReconnect> {
  @override
  void didUpdateWidget(_RefreshOnReconnect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.online && widget.online) {
      context.read<CashClosingCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
