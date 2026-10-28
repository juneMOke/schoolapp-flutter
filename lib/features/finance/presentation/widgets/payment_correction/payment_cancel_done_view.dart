import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/receipt_number_watch_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le résultat d'une annulation : toujours un succès local. L'incertitude porte
/// sur la synchronisation, et elle se dit par une note, jamais par un échec.
///
/// Il propose le **ticket d'annulation** (continuité des tickets RC, lot B) :
/// le promoteur doit avoir un papier pour chaque numéro de sa pile. Le ticket
/// affirme une annulation acquittée, il attend donc l'accusé du serveur — en
/// ligne, quelques secondes ; sinon il attend dans « Tickets à imprimer ».
class PaymentCancelDoneView extends StatefulWidget {
  final String paymentId;
  final VoidCallback onClose;

  const PaymentCancelDoneView({
    super.key,
    required this.paymentId,
    required this.onClose,
  });

  @override
  State<PaymentCancelDoneView> createState() => _PaymentCancelDoneViewState();
}

class _PaymentCancelDoneViewState extends State<PaymentCancelDoneView> {
  late final ReceiptNumberWatchCubit _watch;
  bool _printing = false;
  bool _printed = false;

  @override
  void initState() {
    super.initState();
    _watch = getIt<ReceiptNumberWatchCubit>()
      ..watch(widget.paymentId, cancellation: true);
  }

  @override
  void dispose() {
    _watch.close();
    super.dispose();
  }

  Future<void> _print() async {
    if (_printing) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _printing = true);
    final printed = await printCancellationTicket(
      context,
      paymentId: widget.paymentId,
      messenger: messenger,
    );
    if (!mounted) return;
    setState(() {
      _printing = false;
      _printed = _printed || printed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EteeloResultMedallion(kind: EteeloResultKind.success),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.paymentCorrectionCancelledDone,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.paymentCorrectionSavedOnTablet,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          BlocBuilder<ReceiptNumberWatchCubit, ReceiptNumberWatchState>(
            bloc: _watch,
            builder: (context, watch) {
              final hint = switch (watch.phase) {
                ReceiptNumberPhase.numbered => null,
                ReceiptNumberPhase.deferred => l10n.paymentCancelTicketDeferred,
                _ => l10n.paymentCancelTicketWaiting,
              };
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hint != null) ...[
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],
                  OutlinedButton.icon(
                    key: const ValueKey('payment-cancel-print-ticket'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        AppDimensions.minTouchTarget,
                        AppDimensions.minTouchTarget,
                      ),
                    ),
                    onPressed:
                        watch.phase == ReceiptNumberPhase.numbered && !_printing
                        ? _print
                        : null,
                    icon: const Icon(Icons.print_outlined),
                    label: Text(
                      _printed
                          ? l10n.paymentCancelTicketReprint
                          : l10n.paymentCancelTicketPrint,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FilledButton(
            key: const ValueKey('payment-correction-done-close'),
            onPressed: widget.onClose,
            child: Text(l10n.facturationPaymentCloseLabel),
          ),
        ],
      ),
    );
  }
}
