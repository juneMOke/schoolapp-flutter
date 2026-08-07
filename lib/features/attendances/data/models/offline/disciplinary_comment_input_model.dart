import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_row.dart';

/// Volet `comments[]` de l'agrégat poussé au `/sync` (contrat 1.1.0,
/// `DisciplinaryCommentInput`). **Append-only**, dédupliqué serveur par `id`
/// (`ON CONFLICT DO NOTHING`) : renvoyer la liste complète est sûr.
class DisciplinaryCommentInputModel extends Equatable {
  final String id;
  final String content;
  final String? authorName;

  /// ISO-8601 (heure métier).
  final String createdAt;

  const DisciplinaryCommentInputModel({
    required this.id,
    required this.content,
    this.authorName,
    required this.createdAt,
  });

  factory DisciplinaryCommentInputModel.fromRow(DisciplinaryCommentRow row) =>
      DisciplinaryCommentInputModel(
        id: row.id,
        content: row.content,
        authorName: row.authorName,
        createdAt: EpochIsoHelper.toIso(row.createdAt),
      );

  factory DisciplinaryCommentInputModel.fromJson(Map<String, dynamic> json) =>
      DisciplinaryCommentInputModel(
        id: json['id'] as String,
        content: json['content'] as String,
        authorName: json['authorName'] as String?,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'content': content,
    'authorName': authorName,
    'createdAt': createdAt,
  };

  // `content` SENSIBLE (mineur) : jamais rendu par toString() (fuite debug).
  @override
  bool? get stringify => false;

  @override
  List<Object?> get props => [id, content, authorName, createdAt];
}
