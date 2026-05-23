import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

part 'classroom_member_model.g.dart';

@JsonSerializable()
class ClassroomMemberModel extends Equatable {
  final String id;
  final String studentId;
  final String classroomId;
  final String academicYearId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;

  const ClassroomMemberModel({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
  });

  factory ClassroomMemberModel.fromJson(Map<String, dynamic> json) {
    final model = _$ClassroomMemberModelFromJson(json);
    _validateRequiredField(model.id, 'id');
    _validateRequiredField(model.studentId, 'studentId');
    _validateRequiredField(model.classroomId, 'classroomId');
    _validateRequiredField(model.academicYearId, 'academicYearId');
    _validateRequiredField(model.studentFirstName, 'studentFirstName');
    _validateRequiredField(model.studentLastName, 'studentLastName');
    _validateRequiredField(model.studentGender, 'studentGender');
    return model;
  }

  static void _validateRequiredField(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw FormatException(
        'Invalid classroom member payload: $fieldName is empty',
      );
    }
  }

  Map<String, dynamic> toJson() => _$ClassroomMemberModelToJson(this);

  ClassroomMember toEntity() => ClassroomMember(
    id: id,
    studentId: studentId,
    classroomId: classroomId,
    academicYearId: academicYearId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: ClassroomMemberGender.fromApiValue(studentGender),
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    classroomId,
    academicYearId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
  ];
}
