import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';

import '../staff/staff_builders.dart' show documentTypes;

export '../staff/staff_builders.dart' show document, documentTypes, period;

/// Un agent avec ce que le tableau de bord lit : sexe, catégorie, entrée.
StaffMember agent(
  String id, {
  String lastName = 'Kalala',
  String? middleName = 'Mutombo',
  String firstName = 'Jean',
  StaffSex? sex = StaffSex.male,
  StaffCategory? category = StaffCategory.teacher,
  String? entryDate = '2020-09-01',
  String? jobTitle = 'Enseignant titulaire',
  List<String> branches = const [],
  List<StaffContractPeriod> contracts = const [],
  String? staffNumber = 'CF-AG-0001',
  RecordSyncState syncState = RecordSyncState.synced,
}) => StaffMember(
  id: id,
  lastName: lastName,
  middleName: middleName,
  firstName: firstName,
  sex: sex,
  category: category,
  entryDate: entryDate,
  jobTitle: jobTitle,
  branches: branches,
  contracts: contracts,
  staffNumber: staffNumber,
  syncState: syncState,
);

StaffFileSnapshot snapshotOf(
  List<StaffMember> members, {
  Map<String, List<StaffDocument>> documents = const {},
  bool hasEverSynced = true,
}) => StaffFileSnapshot(
  members: members,
  documentsByMember: documents,
  documentTypes: documentTypes,
  hasEverSynced: hasEverSynced,
);

StaffFileView viewOf(
  List<StaffMember> members, {
  Map<String, List<StaffDocument>> documents = const {},
  String today = '2026-10-24',
  bool documentsVisible = true,
}) => StaffFileView.build(
  snapshotOf(members, documents: documents),
  query: StaffFileQuery.none,
  today: today,
  documentsVisible: documentsVisible,
);
