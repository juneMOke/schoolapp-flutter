import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Des gestes faits hors ligne sur un brouillon que quelqu'un a publié ou
/// abandonné entre-temps (TIMETABLE_DRAFT_ENDED) : jamais rattachés d'office —
/// on les reprend dans un nouveau brouillon, ou on les ignore.
class EndedGesturesNotice extends StatelessWidget {
  final int count;
  final ClassTimetableCubit cubit;

  const EndedGesturesNotice({
    super.key,
    required this.count,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloNotice.warning(l10n.classTimetableEndedNotice(count)),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            PrimaryButton(
              label: l10n.classTimetableEndedResume,
              icon: Icons.restore,
              fullWidth: false,
              onPressed: () => unawaited(_resume(context)),
            ),
            SecondaryButton(
              label: l10n.classTimetableEndedDiscard,
              fullWidth: false,
              onPressed: () => unawaited(cubit.discardEnded()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Future<void> _resume(BuildContext context) async {
    final result = await cubit.resumeEnded();
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.classTimetableSaveFailed,
      ),
      (_) {},
    );
  }
}
