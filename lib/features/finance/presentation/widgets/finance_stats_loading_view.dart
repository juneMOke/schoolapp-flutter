import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsLoadingView extends StatelessWidget {
  const FinanceStatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.financeStatsLoadingA11yLabel,
      readOnly: true,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
