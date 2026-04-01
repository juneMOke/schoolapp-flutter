import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class SearchFormTitle extends StatelessWidget {
  final String label;

  const SearchFormTitle({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}
