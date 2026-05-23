import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Etat erreur uniforme pour les tableaux.
class DataTableErrorState extends StatelessWidget {
  final String label;

  const DataTableErrorState({super.key, required this.label});

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
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                  EteeloDataTableTheme.stateIconContainerSize / 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: EteeloDataTableTheme.stateIconSize,
                color: AppColors.error,
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
