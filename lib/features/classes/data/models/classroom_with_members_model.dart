import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_member_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';

part 'classroom_with_members_model.g.dart';

@JsonSerializable()
class ClassroomWithMembersModel extends Equatable {
  final ClassroomModel classroom;
  final List<ClassroomMemberModel> members;

  const ClassroomWithMembersModel({
    required this.classroom,
    required this.members,
  });

  factory ClassroomWithMembersModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomWithMembersModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomWithMembersModelToJson(this);

  ClassroomWithMembers toEntity() => ClassroomWithMembers(
        classroom: classroom.toEntity(),
        members: members.map((member) => member.toEntity()).toList(growable: false),
      );

  @override
  List<Object?> get props => [classroom, members];
}
