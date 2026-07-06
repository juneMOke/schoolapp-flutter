import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';

/// Corps du POST de création offline (DF-2 `CreateCaseRequest`). `id` = uuid
/// CLIENT honoré (idempotence, régime A). Le `status` n'est **pas** envoyé
/// (forcé OPEN côté serveur). Sert aussi de payload d'outbox (CREATE).
class CreateDisciplinaryCaseOfflineRequestModel extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;

  /// 'yyyy-MM-dd'.
  final String disciplinaryCaseDate;
  final String academicYearId;
  final String title;
  final String content;
  final String category;
  final String severity;
  final String? sanction;

  const CreateDisciplinaryCaseOfflineRequestModel({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.disciplinaryCaseDate,
    required this.academicYearId,
    required this.title,
    required this.content,
    required this.category,
    required this.severity,
    this.sanction,
  });

  factory CreateDisciplinaryCaseOfflineRequestModel.fromRow(
    OfflineDisciplinaryCaseRow row,
  ) => CreateDisciplinaryCaseOfflineRequestModel(
    id: row.id,
    studentId: row.studentId,
    studentFirstName: row.studentFirstName,
    studentLastName: row.studentLastName,
    studentMiddleName: row.studentMiddleName,
    studentGender: row.studentGender,
    disciplinaryCaseDate: row.disciplinaryCaseDate,
    academicYearId: row.academicYearId,
    title: row.title,
    content: row.content,
    category: row.category,
    severity: row.severity,
    sanction: row.sanction,
  );

  factory CreateDisciplinaryCaseOfflineRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => CreateDisciplinaryCaseOfflineRequestModel(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentFirstName: json['studentFirstName'] as String,
    studentLastName: json['studentLastName'] as String,
    studentMiddleName: json['studentMiddleName'] as String?,
    studentGender: (json['studentGender'] as String?) ?? 'OTHER',
    disciplinaryCaseDate: json['disciplinaryCaseDate'] as String,
    academicYearId: json['academicYearId'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    category: (json['category'] as String?) ?? 'DISRUPTIVE_BEHAVIOR',
    severity: (json['severity'] as String?) ?? 'MINOR',
    sanction: json['sanction'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'studentFirstName': studentFirstName,
    'studentLastName': studentLastName,
    'studentMiddleName': studentMiddleName,
    'studentGender': studentGender,
    'disciplinaryCaseDate': disciplinaryCaseDate,
    'academicYearId': academicYearId,
    'title': title,
    'content': content,
    'category': category,
    'severity': severity,
    'sanction': sanction,
  };

  String toJsonString() => jsonEncode(toJson());

  factory CreateDisciplinaryCaseOfflineRequestModel.fromJsonString(
    String payload,
  ) => CreateDisciplinaryCaseOfflineRequestModel.fromJson(
    jsonDecode(payload) as Map<String, dynamic>,
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    disciplinaryCaseDate,
    academicYearId,
    title,
    content,
    category,
    severity,
    sanction,
  ];
}
