import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reassign_classroom_member_request_model.g.dart';

@JsonSerializable()
class ReassignClassroomMemberRequestModel extends Equatable {
  final String targetClassroomId;

  const ReassignClassroomMemberRequestModel({required this.targetClassroomId});

  factory ReassignClassroomMemberRequestModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$ReassignClassroomMemberRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReassignClassroomMemberRequestModelToJson(this);

  @override
  List<Object?> get props => [targetClassroomId];
}
