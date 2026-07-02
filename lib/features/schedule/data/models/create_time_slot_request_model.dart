import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';

/// Corps JSON du POST de création d'un créneau de sonnerie.
///
/// [toJson] omet `label` lorsqu'il est nul (champ optionnel côté contrat).
class CreateTimeSlotRequestModel {
  final int order;
  final String startTime;
  final String endTime;
  final String? label;

  const CreateTimeSlotRequestModel({
    required this.order,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory CreateTimeSlotRequestModel.fromDomain(
    CreateTimeSlotRequest request,
  ) => CreateTimeSlotRequestModel(
    order: request.order,
    startTime: request.startTime,
    endTime: request.endTime,
    label: request.label,
  );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'order': order,
      'startTime': startTime,
      'endTime': endTime,
    };
    if (label != null) json['label'] = label;
    return json;
  }
}
