import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';

part 'moyenne_eleve_model.g.dart';

@JsonSerializable()
class MoyenneEleveModel extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final double? moyenne;

  const MoyenneEleveModel({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.moyenne,
  });

  factory MoyenneEleveModel.fromJson(Map<String, dynamic> json) =>
      _$MoyenneEleveModelFromJson(json);

  Map<String, dynamic> toJson() => _$MoyenneEleveModelToJson(this);

  MoyenneEleve toEntity() => MoyenneEleve(
    studentId: studentId,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    moyenne: moyenne,
  );

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    moyenne,
  ];
}
