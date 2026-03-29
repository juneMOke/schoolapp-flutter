import 'package:flutter/material.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EteeloAppTitle extends StatelessWidget {
  final String subTitle;

  const EteeloAppTitle({super.key, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const Icon(Icons.school, size: 80, color: Colors.indigo),
        const SizedBox(height: 16),
        Text(
          l10n.schoolApp,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subTitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
