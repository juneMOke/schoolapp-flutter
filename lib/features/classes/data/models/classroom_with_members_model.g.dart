// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_with_members_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomWithMembersModel _$ClassroomWithMembersModelFromJson(
  Map<String, dynamic> json,
) => ClassroomWithMembersModel(
  classroom: ClassroomModel.fromJson(json['classroom'] as Map<String, dynamic>),
  members: (json['members'] as List<dynamic>)
      .map((e) => ClassroomMemberModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ClassroomWithMembersModelToJson(
  ClassroomWithMembersModel instance,
) => <String, dynamic>{
  'classroom': instance.classroom,
  'members': instance.members,
};
