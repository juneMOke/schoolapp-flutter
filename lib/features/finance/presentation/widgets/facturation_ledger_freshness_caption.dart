import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fraîcheur du grand-livre (ADR-002) sous les totaux : « à jour à HHhMM » ou
/// « non synchronisé ». Ce repère déclenche la question de coordination entre
/// les 2 postes (FRONT §5), et doit donc dire le vrai à tout instant.
///
/// Deux déclencheurs, et il faut les deux :
///  - une lecture RÉUSSIE des créances — c'est l'affichage initial, qui montre
///    honnêtement la fraîcheur d'AVANT le cycle en cours, puisque les lectures
///    ne l'attendent plus ;
///  - un cycle de rafraîchissement ABOUTI — sinon la légende resterait figée sur
///    l'ancienne heure quand le cycle n'a rien changé au grand-livre : sans
///    créance modifiée, aucune relecture n'émet (états `Equatable`), et
///    personne ne rechargerait `sync_meta.synced_at`, qui a pourtant bougé.
class FacturationLedgerFreshnessCaption extends StatelessWidget {
  final String studentId;

  const FacturationLedgerFreshnessCaption({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<StudentChargesBloc, StudentChargesState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == StudentChargesStatus.success,
          listener: (context, _) =>
              context.read<LedgerFreshnessCubit>().load(studentId),
        ),
        BlocListener<LedgerRevalidationCubit, int>(
          listener: (context, _) =>
              context.read<LedgerFreshnessCubit>().load(studentId),
        ),
      ],
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
