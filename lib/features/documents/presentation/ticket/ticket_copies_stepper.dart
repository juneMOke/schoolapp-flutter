import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Exemplaires  (−) 2 (+) ».
///
/// Les deux bornes **désactivent** leur bouton plutôt que de le cacher : le
/// compteur ne change pas de forme sous le doigt.
class TicketCopiesStepper extends StatelessWidget {
  final int copies;
  final ValueChanged<int> onChanged;

  const TicketCopiesStepper({
    super.key,
    required this.copies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.ticketCopiesLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.ticketCopiesDecrease,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.textPrimary,
          onPressed: copies > TicketCopies.min
              ? () => onChanged(copies - 1)
              : null,
        ),
        SizedBox(
          width: AppDimensions.ticketCopiesValueWidth,
          child: Text(
            '$copies',
            key: const ValueKey('ticketCopiesValue'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.ticketCopiesIncrease,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.textPrimary,
          onPressed: copies < TicketCopies.max
              ? () => onChanged(copies + 1)
              : null,
        ),
      ],
    );
  }
}

/// Le raccourci ponctuel de la visionneuse d'un ticket : parti des
/// exemplaires par défaut (Finances ▸ Imprimante de tickets), il ne vaut que
/// pour cette impression.
class TicketCopiesOption extends StatelessWidget {
  final ValueNotifier<int> copies;

  const TicketCopiesOption({super.key, required this.copies});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: copies,
    builder: (context, value, _) => TicketCopiesStepper(
      copies: value,
      onChanged: (next) => copies.value = TicketCopies.clamp(next),
    ),
  );
}
