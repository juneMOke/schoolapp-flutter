import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_overview_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/dashboard_screen.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trésorerie ▸ Tableau de bord.
class TreasuryDashboardPage extends StatelessWidget {
  const TreasuryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<TreasuryOverviewCubit>(
    create: (_) => GetIt.instance<TreasuryOverviewCubit>()..load(),
    // Relire le tableau de bord le remonte : l'évolution et les rapports
    // repartent avec lui.
    child: Builder(
      builder: (context) => TreasuryRefreshScope(
        onRefresh: context.read<TreasuryOverviewCubit>().load,
        child: const AppPageBackground(
          width: PageContentWidth.wide,
          scrollable: true,
          child: _DashboardBody(),
        ),
      ),
    ),
  );
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canWrite = PermissionGate.allowsAccess(
      context,
      kTreasuryRegisterWriteAccess,
    );
    return TreasuryDashboardScreen(
      onOpenClosing: () => _open(
        context,
        MenuConstants.treasuryClosingId,
        l10n.subMenuTreasuryClosing,
      ),
      onConfigure: canWrite
          ? () => _open(
              context,
              MenuConstants.treasuryConfigId,
              l10n.subMenuTreasuryConfig,
            )
          : null,
    );
  }

  static void _open(BuildContext context, String subMenuId, String title) =>
      context.read<NavigationBloc>().add(
        SubMenuItemSelected(
          menuId: MenuConstants.treasuryMenuId,
          subMenuId: subMenuId,
          title: title,
        ),
      );
}
