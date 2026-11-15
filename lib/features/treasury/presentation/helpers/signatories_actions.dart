import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/report_signatories_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/signatories_edit_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Modifier les signataires » : la modale, puis son toast.
Future<void> editReportSignatories(
  BuildContext context,
  ReportSignatoriesCubit cubit,
) async {
  final current = cubit.state.signatories;
  if (current == null) return;
  final outcome = await showSignatoriesEditDialog(
    context,
    current: current,
    onSave: cubit.save,
  );
  if (outcome == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  AppSnackBar.showSuccess(context, switch (outcome) {
    SignatoriesOutcome.saved => l10n.treasurySignatoriesSaved,
    SignatoriesOutcome.defaultsRestored => l10n.treasurySignatoriesRestored,
  });
}
