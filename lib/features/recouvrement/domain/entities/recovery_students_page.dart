import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';

/// Un élève de la liste nominative (E) : ses montants par devise, sa
/// situation, et s'il est en ordre selon la règle posée.
class RecoveryStudentRow extends Equatable {
  final String studentId;
  final String displayName;
  final String? matriculationNumber;
  final String? parentName;
  final String? classroomId;

  /// `null` pour un non-affecté.
  final String? classroomName;
  final List<Money> due;

  /// Versé, brut.
  final List<Money> paid;
  final List<Money> outstanding;
  final StudentChargeStatus situation;
  final bool inOrder;

  const RecoveryStudentRow({
    required this.studentId,
    required this.displayName,
    this.matriculationNumber,
    this.parentName,
    this.classroomId,
    this.classroomName,
    required this.due,
    required this.paid,
    required this.outstanding,
    required this.situation,
    required this.inOrder,
  });

  @override
  List<Object?> get props => [
    studentId,
    displayName,
    matriculationNumber,
    parentName,
    classroomId,
    classroomName,
    due,
    paid,
    outstanding,
    situation,
    inOrder,
  ];
}

/// Compteurs des trois onglets (après le filtre de situation, avant la
/// recherche).
class RecoveryTabCounts extends Equatable {
  final int toChase;
  final int inOrder;
  final int all;

  const RecoveryTabCounts({
    required this.toChase,
    required this.inOrder,
    required this.all,
  });

  @override
  List<Object?> get props => [toChase, inOrder, all];
}

/// Une page de `GET /finance-stats/recovery/students`.
class RecoveryStudentsPage extends Equatable {
  final DateTime situationAt;
  final int pendingWrites;

  /// Le titre R10, composé par le serveur — le même que celui des exports.
  final String title;
  final String? perimeterLabel;
  final List<String> currencies;
  final bool atLeastAvailable;
  final RecoveryTabCounts counts;
  final RecoverySituationCounts situationCounts;
  final List<RecoveryStudentRow> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final DateTime? cachedAt;

  const RecoveryStudentsPage({
    required this.situationAt,
    required this.pendingWrites,
    required this.title,
    this.perimeterLabel,
    required this.currencies,
    required this.atLeastAvailable,
    required this.counts,
    required this.situationCounts,
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.cachedAt,
  });

  bool get isMixed => currencies.length > 1;

  RecoveryStudentsPage cached(DateTime at) => RecoveryStudentsPage(
    situationAt: situationAt,
    pendingWrites: pendingWrites,
    title: title,
    perimeterLabel: perimeterLabel,
    currencies: currencies,
    atLeastAvailable: atLeastAvailable,
    counts: counts,
    situationCounts: situationCounts,
    content: content,
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
    cachedAt: at,
  );

  @override
  List<Object?> get props => [
    situationAt,
    pendingWrites,
    title,
    perimeterLabel,
    currencies,
    atLeastAvailable,
    counts,
    situationCounts,
    content,
    page,
    size,
    totalElements,
    totalPages,
    cachedAt,
  ];
}

/// Le format d'un export du tableau de bord.
enum RecoveryExportFormat { pdf, xlsx }

/// Un export reçu du serveur. Les octets sont gardés par la visionneuse :
/// chaque PDF consomme un numéro de pièce.
class RecoveryExportFile extends Equatable {
  final RecoveryExportFormat format;
  final Uint8List bytes;
  final String fileName;
  final DateTime? situationAt;

  const RecoveryExportFile({
    required this.format,
    required this.bytes,
    required this.fileName,
    this.situationAt,
  });

  @override
  List<Object?> get props => [format, bytes.length, fileName, situationAt];
}
