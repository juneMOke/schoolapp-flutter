import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/tickets_to_print/tickets_to_print_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de « Tickets à imprimer ».
///
/// Cochable quand le ticket est prêt ([onChanged] posé) ; grisée sinon. Toute
/// la ligne est la cible du geste — au moins 48 dp de haut.
class TicketPrintJobTile extends StatelessWidget {
  final TicketPrintJob job;
  final bool selected;

  /// `null` : la ligne ne se coche pas (numéro attendu, ou lot en cours).
  final ValueChanged<bool>? onChanged;

  const TicketPrintJobTile({
    super.key,
    required this.job,
    this.selected = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onChanged = this.onChanged;
    final ready = job.isReady;
    final muted = ready ? AppColors.textSecondary : AppColors.textMuted;
    final student = job.studentFullName.trim();
    final problem = _problemLabel(l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Material(
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brSm,
          side: BorderSide(
            color: selected ? AppColors.bleuArdoise : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged(!selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingS,
                vertical: AppDimensions.spacingS,
              ),
              child: Row(
                children: [
                  if (ready)
                    Checkbox(
                      value: selected,
                      onChanged: onChanged == null
                          ? null
                          : (value) => onChanged(value ?? false),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(AppDimensions.spacingS),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.receiptNumber ?? l10n.ticketsToPrintNumberPending,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: ready
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        Text(
                          student.isEmpty
                              ? l10n.ticketsToPrintUnknownStudent
                              : student,
                          style: AppTextStyles.body.copyWith(color: muted),
                        ),
                        Text(
                          [
                            ticketPrintJobKindLabel(job.kind, l10n),
                            formatSchoolDateTime(job.enteredAt),
                          ].join(' · '),
                          style: AppTextStyles.caption.copyWith(color: muted),
                        ),
                        if (problem != null)
                          Text(
                            l10n.ticketsToPrintLastProblem(problem),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  // Flexible : au texte ×1,3 sur un téléphone, deux devises
                  // passent à la ligne plutôt que de pousser la colonne.
                  Flexible(
                    flex: 2,
                    child: Text(
                      job.amount.entries.map(MoneyFormat.format).join(' + '),
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bodyStrong.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Le dernier échec, dans la langue de l'écran ; `null` sans échec connu.
  String? _problemLabel(AppLocalizations l10n) {
    final name = job.lastProblem;
    if (name == null) return null;
    for (final problem in ThermalPrinterProblem.values) {
      if (problem.name == name) {
        return thermalPrinterProblemMessage(l10n, problem);
      }
    }
    return null;
  }
}
