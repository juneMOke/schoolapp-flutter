import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

part 'time_slot_model.g.dart';

/// Modèle du `TimeSlotDto` (créneau de sonnerie).
///
/// [startTime]/[endTime] restent des chaînes `HH:mm:ss` (heures pures) — cf.
/// [TimeSlot].
@JsonSerializable()
class TimeSlotModel extends Equatable {
  final String id;
  final int order;
  final String startTime;
  final String endTime;
  final String? label;

  const TimeSlotModel({
    required this.id,
    required this.order,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotModelToJson(this);

  TimeSlot toEntity() => TimeSlot(
    id: id,
    order: order,
    startTime: startTime,
    endTime: endTime,
    label: label,
  );

  @override
  List<Object?> get props => [id, order, startTime, endTime, label];
}
