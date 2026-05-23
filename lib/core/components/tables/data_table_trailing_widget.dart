import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';

/// Widget deleguant le rendu trailing a une registry OCP.
class DataTableTrailingWidget extends StatelessWidget {
  final DataTableTrailingSpec spec;
  final Map<DataTableTrailingType, DataTableTrailingBuilder> customBuilders;

  const DataTableTrailingWidget({
    super.key,
    required this.spec,
    this.customBuilders = const {},
  });

  @override
  Widget build(BuildContext context) {
    return DataTableTrailingRegistry.build(
      context,
      spec,
      customBuilders: customBuilders,
    );
  }
}
