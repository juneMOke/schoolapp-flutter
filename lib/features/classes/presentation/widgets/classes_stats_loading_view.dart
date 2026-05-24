import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsLoadingView extends StatelessWidget {
  const ClassesStatsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.classesStatsLoadingA11yLabel,
      readOnly: true,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
