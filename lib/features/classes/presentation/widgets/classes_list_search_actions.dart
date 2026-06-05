import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

class ClassesListSearchActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback? onSearch;
  final bool isSearching;
  final String clearLabel;
  final String searchLabel;

  const ClassesListSearchActions({
    super.key,
    required this.onReset,
    required this.onSearch,
    required this.isSearching,
    required this.clearLabel,
    required this.searchLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppDimensions.spacingS,
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(7),
          child: EteeloButton.ghost(
            onPressed: onReset,
            icon: Icons.refresh_rounded,
            label: clearLabel,
          ),
        ),
        FocusTraversalOrder(
          order: const NumericFocusOrder(8),
          child: EteeloButton.primary(
            onPressed: onSearch,
            icon: Icons.search_rounded,
            label: searchLabel,
            isLoading: isSearching,
          ),
        ),
      ],
    );
  }
}
