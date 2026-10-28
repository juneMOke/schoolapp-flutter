import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// « n tickets prêts à imprimer » — mène à « Tickets à imprimer »
/// (continuité des tickets RC, lot D).
///
/// Masqué à zéro. Son compte est lu dans la file LOCALE de ce poste, jamais
/// sur le serveur : posé sur le tableau de bord Finances, il reste à part de
/// ses chiffres (règle 14 — le tableau de bord n'a qu'une source, le serveur).
/// Il s'affiche aussi là où le caissier encaisse : c'est lui qui a les tickets
/// en file, et il n'a pas forcément le tableau de bord.
class TicketsToPrintBanner extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TicketsToPrintBanner({super.key, this.padding = EdgeInsets.zero});

  /// Ni bandeau ni lecture de la file pour qui la garde refuserait la page :
  /// sans `editique.read`, aucun ticket n'y deviendrait imprimable ; sans le
  /// sous-menu Facturations, le bandeau du tableau de bord mènerait à un
  /// refus. La question posée est celle du routeur, sur la même adresse.
  @override
  Widget build(BuildContext context) => PermissionAware(
    builder: (context) {
      final auth = PermissionGate.maybeBlocOf(context);
      final allowed =
          auth == null ||
          canAccessLocation(
            Uri.parse(AppRoutesNames.ticketsToPrint),
            auth.state.permissions,
          );
      if (!allowed) return const SizedBox.shrink();
      return BlocProvider<TicketPrintQueueCubit>(
        create: (_) => getIt<TicketPrintQueueCubit>()..load(),
        child: _Banner(padding: padding),
      );
    },
  );
}

class _Banner extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const _Banner({required this.padding});

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<TicketPrintQueueCubit>();
    await context.push(AppRoutesNames.ticketsToPrint);
    // Au retour, des tickets ont pu sortir.
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<SyncStatusCubit, SyncStatusState>(
      // Une synchronisation terminée peut avoir scellé des reçus.
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SyncStatus.synced,
      listener: (context, _) => context.read<TicketPrintQueueCubit>().load(),
      child: BlocBuilder<TicketPrintQueueCubit, TicketPrintQueueState>(
        buildWhen: (previous, current) =>
            previous.ready.length != current.ready.length,
        builder: (context, state) {
          final count = state.ready.length;
          if (count == 0) return const SizedBox.shrink();
          return Padding(
            padding: padding,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.warning),
                borderRadius: AppRadius.brSm,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: LeadingTrailingRow(
                  gap: AppDimensions.spacingS,
                  leading: Row(
                    children: [
                      const Icon(
                        Icons.print_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          l10n.ticketsToPrintBanner(count),
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: EteeloButton.secondary(
                    label: l10n.ticketsToPrintBannerAction,
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: false,
                    onPressed: () => _open(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
