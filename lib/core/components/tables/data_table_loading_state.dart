import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';

/// Etat de chargement uniforme pour les tableaux.
class DataTableLoadingState extends StatelessWidget {
  final String? label;

  const DataTableLoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EteeloDataTableTheme.statePadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!, style: EteeloDataTableTheme.cellRegularStyle),
            ],
          ],
        ),
      ),
    );
  }
}
