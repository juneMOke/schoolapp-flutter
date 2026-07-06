import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';

/// Réponse du pull delta `GET /api/v1/sync/classrooms` (CF2).
///
/// `serverCursor` = borne haute `updated_at` renvoyée par le serveur, à
/// repersister via [SyncMetaDao] pour le prochain `updatedSince`. Parsing manuel
/// (retrofit appelle `ClassroomDeltaModel.fromJson`), tolérant à l'absence de
/// listes (delta vide).
class ClassroomDeltaModel extends Equatable {
  final List<ClassroomDto> classrooms;
  final List<ClassroomMemberDto> members;
  final int? serverCursor;

  const ClassroomDeltaModel({
    this.classrooms = const [],
    this.members = const [],
    this.serverCursor,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory ClassroomDeltaModel.fromJson(Map<String, dynamic> json) {
    final rawClassrooms = (json['classrooms'] as List<dynamic>?) ?? const [];
    final rawMembers = (json['members'] as List<dynamic>?) ?? const [];
    return ClassroomDeltaModel(
      classrooms: rawClassrooms
          .map((e) => ClassroomDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      members: rawMembers
          .map((e) => ClassroomMemberDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      serverCursor: _asIntOrNull(json['serverCursor']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'classrooms': classrooms.map((e) => e.toMap()).toList(),
    'members': members.map((e) => e.toMap()).toList(),
    'serverCursor': serverCursor,
  };

  bool get isEmpty => classrooms.isEmpty && members.isEmpty;

  @override
  List<Object?> get props => [classrooms, members, serverCursor];
}
