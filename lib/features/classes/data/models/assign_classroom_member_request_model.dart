import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assign_classroom_member_request_model.g.dart';

/// Corps du `POST /api/v1/classrooms/{classroomId}/members`
/// (schéma `AssignClassroomMemberRequest`) : **première** affectation d'une
/// inscription `COMPLETED` à une classe. Un seul champ requis — la classe cible
/// voyage dans le chemin, jamais dans le corps.
///
/// L'élève n'ayant pas encore de ligne roster, l'identifiant transporté est
/// celui de son **dossier d'inscription** : envoyer un `classroomMemberId` sur
/// cette route retourne 404.
@JsonSerializable()
class AssignClassroomMemberRequestModel extends Equatable {
  final String enrollmentId;

  const AssignClassroomMemberRequestModel({required this.enrollmentId});

  factory AssignClassroomMemberRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => _$AssignClassroomMemberRequestModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AssignClassroomMemberRequestModelToJson(this);

  @override
  List<Object?> get props => [enrollmentId];
}
