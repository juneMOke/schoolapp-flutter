import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/periode_notation_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';

part 'cours_notation_detail_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CoursNotationDetailModel extends Equatable {
  final String coursId;
  final String classroomId;
  final String? brancheNom;
  final int effectif;
  final List<PeriodeNotationModel> periodes;

  const CoursNotationDetailModel({
    required this.coursId,
    required this.classroomId,
    this.brancheNom,
    required this.effectif,
    required this.periodes,
  });

  factory CoursNotationDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CoursNotationDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoursNotationDetailModelToJson(this);

  CoursNotationDetail toEntity() => CoursNotationDetail(
    coursId: coursId,
    classroomId: classroomId,
    brancheNom: brancheNom,
    effectif: effectif,
    periodes: periodes
        .map((periode) => periode.toEntity())
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [
    coursId,
    classroomId,
    brancheNom,
    effectif,
    periodes,
  ];
}
