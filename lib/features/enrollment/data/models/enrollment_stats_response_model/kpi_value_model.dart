import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/kpi_value.dart';

class KpiValueModel {
  final int value;
  final int? percentOfTotal;

  const KpiValueModel({required this.value, this.percentOfTotal});

  factory KpiValueModel.fromJson(Map<String, dynamic> json) {
    return KpiValueModel(
      value: (json['value'] as num).toInt(),
      percentOfTotal: (json['percentOfTotal'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'value': value,
    'percentOfTotal': percentOfTotal,
  };

  KpiValue toEntity() => KpiValue(value: value, percentOfTotal: percentOfTotal);
}
