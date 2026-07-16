import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fraîcheur du grand-livre (ADR-002) sous les totaux : « à jour à HHhMM » ou
/// « non synchronisé ». Recharge la valeur à chaque lecture RÉUSSIE des créances
/// — le rafraîchissement ciblé a alors déjà mis à jour `sync_meta.synced_at`.
/// Ce repère déclenche la question de coordination entre les 2 postes (FRONT §5).
class FacturationLedgerFreshnessCaption extends StatelessWidget {
  final String studentId;

  const FacturationLedgerFreshnessCaption({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<StudentChargesBloc, StudentChargesState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.status == StudentChargesStatus.success,
      listener: (context, _) =>
          context.read<LedgerFreshnessCubit>().load(studentId),
      child: BlocBuilder<LedgerFreshnessCubit, int?>(
        builder: (context, syncedAtMs) {
          final label = syncedAtMs == null
              ? l10n.facturationFreshnessNever
              : l10n.facturationFreshnessAt(_formatTime(context, syncedAtMs));
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(BuildContext context, int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(dt));
  }
}
