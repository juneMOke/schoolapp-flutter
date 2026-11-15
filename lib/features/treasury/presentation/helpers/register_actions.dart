import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_adjust_dialog.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_create_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes d'écriture de la configuration, chacun suivi de son toast.
class RegisterActions {
  final BuildContext context;
  final CashRegistersCubit cubit;
  final IdGenerator ids;

  const RegisterActions(this.context, this.cubit, this.ids);

  Future<void> create() async {
    final created = await showRegisterCreateDialog(
      context,
      existing: [for (final config in cubit.state.registers) config.register],
      onCreate: (currency, name, amount) => cubit.create(
        currency: currency,
        name: name,
        openingAmountInCents: amount,
      ),
    );
    if (created == null || !context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      AppLocalizations.of(context)!.treasuryRegisterCreated(
        created.name,
        TreasuryFormat.money(created.amountInCents, created.currency),
      ),
    );
  }

  Future<void> adjust(RegisterConfig config) async {
    // Une clé de rejeu par ouverture de la modale : un double appui, ou un
    // renvoi après une coupure, ne crée jamais deux ajustements.
    final id = ids.newId();
    final adjustment = await showRegisterAdjustDialog(
      context,
      config: config,
      onAdjust: (shown, next, reason) => cubit.adjust(
        registerId: config.register.id,
        id: id,
        shownExpectedInCents: shown,
        newAmountInCents: next,
        reason: reason,
      ),
    );
    if (adjustment == null || !context.mounted) return;
    AppSnackBar.showSuccess(
      context,
      AppLocalizations.of(context)!.treasuryRegisterAdjusted(
        config.register.name,
        TreasuryFormat.signedMoney(
          adjustment.deltaInCents,
          config.register.currency,
        ),
        adjustment.number,
      ),
    );
  }
}
