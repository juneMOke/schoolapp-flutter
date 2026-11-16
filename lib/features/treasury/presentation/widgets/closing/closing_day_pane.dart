import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_date_picker.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_day_view.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_step_gestures.dart';

/// La journée et sa navigation ‹ date › : seule en Journalier (avec les
/// filtres, le sélecteur de date, le glissement et les flèches du clavier),
/// ou dans le volet de droite à côté de la semaine ou du mois (sans eux — la
/// période garde les siens).
class ClosingDayPane extends StatelessWidget {
  final CashClosingState state;
  final ClosingCallbacks callbacks;
  final bool online;

  /// Journalier · Hebdomadaire · Mensuel ; `null` dans le volet de droite.
  final Widget? filters;

  /// Seule à l'écran : sélecteur de date, glissement, ← →.
  final bool standalone;

  const ClosingDayPane({
    super.key,
    required this.state,
    required this.callbacks,
    required this.online,
    this.filters,
    this.standalone = true,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CashClosingCubit>();
    final businessDate = state.businessDate;
    final known = state.historyStart != null;
    final previous = cubit.nextDay(-1) == null ? null : () => cubit.step(-1);
    final next = cubit.nextDay(1) == null ? null : () => cubit.step(1);
    final day = ClosingDayView(
      state: state,
      callbacks: callbacks,
      online: online,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La barre reste dès que le serveur a dit quel jour on est, même si
        // la journée affichée échoue : on peut toujours en sortir.
        if (businessDate != null) ...[
          DayNavBar(
            date: state.date,
            isToday: state.date == businessDate,
            onPrevious: previous,
            onNext: next,
            onToday: cubit.goToday,
            filters: known ? filters : null,
            onPickDate: standalone && known ? () => _pickDate(context) : null,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (standalone)
          TreasuryStepGestures(onPrevious: previous, onNext: next, child: day)
        else
          day,
      ],
    );
  }

  /// Le sélecteur de date du Journalier : borné au début de l'historique et
  /// à aujourd'hui, dimanches exclus (R4).
  Future<void> _pickDate(BuildContext context) async {
    final today = state.businessDate;
    final first = state.historyStart;
    if (today == null || first == null) return;
    final cubit = context.read<CashClosingCubit>();
    final picked = await showTreasuryDatePicker(
      context,
      initialDate: state.date,
      firstDate: first,
      lastDate: today,
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
    );
    if (picked == null || !context.mounted) return;
    await cubit.load(picked);
  }
}
