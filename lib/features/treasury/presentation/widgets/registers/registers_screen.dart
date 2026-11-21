import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_register_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/new_register_tile.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_button.dart';

/// Trésorerie ▸ Configuration des caisses : une carte par caisse, dans l'ordre
/// de création, puis la tuile « + » (promoteur), puis la note « Bon à savoir ».
///
/// [onCreate] et [onAdjust] valent `null` hors promoteur : les gestes
/// disparaissent et l'encadré « Consultation seule » les remplace (§04).
class RegistersScreen extends StatelessWidget {
  final VoidCallback? onCreate;
  final ValueChanged<RegisterConfig>? onAdjust;

  /// La journée d'une caisse dans Clôture de caisse.
  final VoidCallback? onSeeDay;

  /// L'instant de référence de la pastille « Nouvelle » (injecté en test).
  final DateTime Function() now;

  const RegistersScreen({
    super.key,
    this.onCreate,
    this.onAdjust,
    this.onSeeDay,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CashRegistersCubit, CashRegistersState>(
      builder: (context, state) {
        final create = _createIfAvailable(state);
        // Ctrl+N : « Nouvelle caisse », tant qu'une devise reste sans caisse.
        // Le raccourci reste posé (l'arbre ne change pas de forme) et ne
        // prend la touche que si le bouton est offert.
        return PageActionShortcut(
          action: PageAction.create,
          onInvoke: onCreate,
          isAllowed: () => create != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloPageHeader(
                titleStyle: TreasuryTitle.style(context),
                eyebrow: l10n.menuTreasury,
                title: l10n.treasuryConfigTitle,
                subtitle: l10n.treasuryConfigSubtitle,
                actions: [
                  ...TreasuryRefreshButton.headerActions(context),
                  if (create != null)
                    EteeloButton.primary(
                      label: l10n.treasuryNewRegister,
                      icon: Icons.add,
                      onPressed: create,
                      fullWidth: false,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _body(context, state, create),
            ],
          ),
        );
      },
    );
  }

  /// La création n'est offerte que s'il reste une devise sans caisse.
  VoidCallback? _createIfAvailable(CashRegistersState state) {
    if (state.status != CashRegistersStatus.ready) return null;
    final registers = [for (final c in state.registers) c.register];
    return CashRegisterRules.availableCurrencies(registers).isEmpty
        ? null
        : onCreate;
  }

  Widget _body(
    BuildContext context,
    CashRegistersState state,
    VoidCallback? create,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (state.status) {
      CashRegistersStatus.loading => EteeloListSkeleton(
        rowCount: 2,
        pillCount: 1,
        showAvatar: false,
        semanticsLabel: l10n.treasuryRegistersLoading,
      ),
      CashRegistersStatus.failure => TreasuryResultsErrorState(
        failure: state.failure ?? const ServerFailure(),
        onRetry: context.read<CashRegistersCubit>().load,
      ),
      _ when state.registers.isEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloEmptyResult(
            label: l10n.treasuryEmptyTitle,
            description: l10n.treasuryEmptyConfig,
            medallionIcon: Icons.payments_outlined,
            fullWidthCard: true,
            primaryAction: create == null
                ? null
                : EteeloButton.primary(
                    label: l10n.treasuryCreateRegister,
                    icon: Icons.add,
                    onPressed: create,
                    fullWidth: false,
                  ),
          ),
          if (onCreate == null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ReadOnlyNote(text: l10n.treasuryReadOnlyPromoter),
          ],
        ],
      ),
      _ => _grid(context, state.registers, create),
    };
  }

  Widget _grid(
    BuildContext context,
    List<RegisterConfig> registers,
    VoidCallback? create,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final adjust = onAdjust;
    final at = now();
    final count = registers.length + (create == null ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloGridView(
          itemCount: count,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasuryRegisterCardMinWidth,
          spacing: AppSpacing.lg,
          itemBuilder: (context, index) {
            if (index == registers.length) {
              return NewRegisterTile(onTap: create!);
            }
            final config = registers[index];
            return RegisterCard(
              key: ValueKey(config.register.id),
              config: config,
              isNew: CashRegisterRules.isNew(config.register, at),
              onAdjust: adjust == null ? null : () => adjust(config),
              onSeeDay: onSeeDay,
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (onCreate == null && adjust == null) ...[
          _ReadOnlyNote(text: l10n.treasuryReadOnlyPromoter),
          const SizedBox(height: AppSpacing.lg),
        ],
        const GoodToKnowNote(),
      ],
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  final String text;

  const _ReadOnlyNote({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadius.brMd,
    ),
    child: Row(
      children: [
        const Icon(
          Icons.visibility_outlined,
          size: AppSpacing.lg + 2,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
