// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSlotModel _$TimeSlotModelFromJson(Map<String, dynamic> json) =>
    TimeSlotModel(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$TimeSlotModelToJson(TimeSlotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order': instance.order,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'label': instance.label,
    };
