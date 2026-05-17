import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Etat vide uniforme pour les tableaux.
class DataTableEmptyState extends StatelessWidget {
  final String label;

  const DataTableEmptyState({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EteeloDataTableTheme.statePadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: EteeloDataTableTheme.stateIconContainerSize,
              height: EteeloDataTableTheme.stateIconContainerSize,
              decoration: BoxDecoration(
                color: AppColors.stateHover,
                borderRadius: BorderRadius.circular(
                  EteeloDataTableTheme.stateIconContainerSize / 2,
                ),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: EteeloDataTableTheme.stateIconSize,
                color: AppColors.bleuArdoise,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              textAlign: TextAlign.center,
              style: EteeloDataTableTheme.cellStrongStyle,
            ),
          ],
        ),
      ),
    );
  }
}
