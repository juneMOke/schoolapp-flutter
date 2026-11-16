import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/report_signatories_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/signatories_actions.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/report_signatories_section.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/register_actions.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/registers_screen.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';

/// Trésorerie ▸ Configuration.
class CashRegistersPage extends StatelessWidget {
  const CashRegistersPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<CashRegistersCubit>(
        create: (_) => GetIt.instance<CashRegistersCubit>()..load(),
      ),
      BlocProvider<ReportSignatoriesCubit>(
        create: (_) => GetIt.instance<ReportSignatoriesCubit>()..load(),
      ),
    ],
    child: Builder(
      builder: (context) => TreasuryRefreshScope(
        onRefresh: () => Future.wait([
          context.read<CashRegistersCubit>().load(),
          context.read<ReportSignatoriesCubit>().load(),
        ]),
        child: const AppPageBackground(
          width: PageContentWidth.wide,
          scrollable: true,
          child: _RegistersBody(),
        ),
      ),
    ),
  );
}

class _RegistersBody extends StatelessWidget {
  const _RegistersBody();

  @override
  Widget build(BuildContext context) {
    final actions = RegisterActions(
      context,
      context.read<CashRegistersCubit>(),
      GetIt.instance<IdGenerator>(),
    );
    // Le serveur vérifie le droit ; l'écran ne fait que masquer le geste.
    final canWrite = PermissionGate.allowsAccess(
      context,
      kTreasuryRegisterWriteAccess,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistersScreen(
          onCreate: canWrite ? actions.create : null,
          onAdjust: canWrite ? actions.adjust : null,
          onSeeDay: () => context.read<NavigationBloc>().add(
            SubMenuItemSelected(
              menuId: MenuConstants.treasuryMenuId,
              subMenuId: MenuConstants.treasuryClosingId,
              title: AppLocalizations.of(context)!.subMenuTreasuryClosing,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ReportSignatoriesSection(
          onEdit: canWrite
              ? () => editReportSignatories(
                  context,
                  context.read<ReportSignatoriesCubit>(),
                )
              : null,
        ),
      ],
    );
  }
}
