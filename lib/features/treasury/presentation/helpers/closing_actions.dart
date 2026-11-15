import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_dialog.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/reopen_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la clôture, chacun suivi de son toast. Chaque geste tire sa
/// clé de rejeu **une fois**, à l'ouverture : un double appui ou un renvoi
/// après coupure ne clôture jamais deux fois.
class ClosingActions {
  final BuildContext context;
  final CashClosingCubit cubit;
  final IdGenerator ids;

  const ClosingActions(this.context, this.cubit, this.ids);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Future<void> close(CashDaySummary summary) async {
    final id = ids.newId();
    final currency = summary.register.currency;
    final result = await showClosingDialog(
      context,
      summary: summary,
      date: cubit.state.date,
      latest: () => cubit.state.day?.registers
          .where((s) => s.register.id == summary.register.id)
          .firstOrNull,
      onClose:
          ({
            required matches,
            required shownExpectedInCents,
            declaredAmountInCents,
            justification,
          }) => cubit.closeRegister(
            id: id,
            registerId: summary.register.id,
            matches: matches,
            shownExpectedInCents: shownExpectedInCents,
            declaredAmountInCents: declaredAmountInCents,
            justification: justification,
          ),
    );
    if (result == null || !context.mounted) return;
    result.fold(
      (failure) {
        final closure = failure is TreasuryRefusalFailure
            ? failure.closure
            : null;
        if (closure != null) {
          AppSnackBar.showInfo(
            context,
            _l10n.treasuryAlreadyClosedToast(
              TreasuryFormat.time(closure.closedAt),
              closure.closedByName,
            ),
          );
        } else {
          AppSnackBar.showError(
            context,
            _l10n.treasurySaveFailed(_l10n.treasuryFailureReason(failure)),
          );
        }
      },
      (closure) => AppSnackBar.showSuccess(
        context,
        closure.hasGap
            ? _l10n.treasuryClosedToastGap(
                summary.register.name,
                TreasuryFormat.signedMoney(closure.gapInCents, currency),
              )
            : _l10n.treasuryClosedToastMatched(
                summary.register.name,
                TreasuryFormat.money(closure.declaredInCents, currency),
              ),
      ),
    );
  }

  Future<void> reopen(CashDaySummary summary) async {
    final closure = summary.closure;
    if (closure == null) return;
    final id = ids.newId();
    final reopened = await showReopenDialog(
      context,
      registerName: summary.register.name,
      onReopen: (reason) =>
          cubit.reopen(closureId: closure.id, id: id, reason: reason),
    );
    if (reopened && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        _l10n.treasuryReopened(
          summary.register.name,
          TreasuryFormat.time(closure.closedAt),
        ),
      );
    }
  }

  Future<void> answer(CashMovement movement, bool alreadyCounted) async {
    final failure = await cubit.confirmAfterClosure(
      movementId: movement.id,
      id: ids.newId(),
      alreadyCounted: alreadyCounted,
    );
    if (!context.mounted) return;
    if (failure != null) {
      AppSnackBar.showError(
        context,
        _l10n.treasurySaveFailed(_l10n.treasuryFailureReason(failure)),
      );
      return;
    }
    AppSnackBar.showSuccess(
      context,
      alreadyCounted
          ? _l10n.treasuryAfterClosureToastAlready
          : _l10n.treasuryAfterClosureToastToday,
    );
  }
}
