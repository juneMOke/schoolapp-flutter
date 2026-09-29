import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

StaffMember member(
  String id, {
  String lastName = 'Kalala',
  String? middleName = 'Mutombo',
  String firstName = 'Jean',
  StaffCategory? category = StaffCategory.teacher,
  String? jobTitle = 'Enseignant titulaire',
  List<String> branches = const [],
  List<StaffContractPeriod> contracts = const [],
  String? staffNumber = 'CF-AG-0001',
  StaffSyncState syncState = StaffSyncState.synced,
}) => StaffMember(
  id: id,
  lastName: lastName,
  middleName: middleName,
  firstName: firstName,
  category: category,
  jobTitle: jobTitle,
  branches: branches,
  contracts: contracts,
  staffNumber: staffNumber,
  syncState: syncState,
);

StaffContractPeriod period(
  StaffContractKind? kind, {
  String from = '2025-09-01',
  String? endsOn,
  StaffPayMode? payMode,
  String id = 'c-1',
}) => StaffContractPeriod(
  contractId: id,
  kind: kind,
  payMode: payMode,
  effectiveFrom: from,
  endsOn: endsOn,
);

StaffDocument document(
  String memberId,
  String code, {
  StaffSyncState syncState = StaffSyncState.synced,
}) => StaffDocument(
  id: '$memberId-$code',
  staffMemberId: memberId,
  code: StaffDocumentCode.fromWire(code),
  rawCode: code,
  source: StaffDocumentSource.scan,
  capturedAt: '2026-07-04T10:00:00.000Z',
  mimeType: 'image/jpeg',
  sizeBytes: 1000,
  syncState: syncState,
);

/// Le référentiel servi par le back : identité et diplôme pour tous, le
/// reste selon le contrat.
const List<StaffDocumentType> documentTypes = [
  StaffDocumentType(
    code: StaffDocumentCode.identity,
    rawCode: 'ID',
    label: "Pièce d'identité",
    alwaysRequired: true,
    requiredFor: {},
  ),
  StaffDocumentType(
    code: StaffDocumentCode.diploma,
    rawCode: 'DP',
    label: 'Diplôme',
    alwaysRequired: true,
    requiredFor: {},
  ),
  StaffDocumentType(
    code: StaffDocumentCode.appointmentLetter,
    rawCode: 'LD',
    label: 'Lettre de désignation',
    alwaysRequired: false,
    requiredFor: {StaffContractKind.permanent, StaffContractKind.conventionne},
  ),
  StaffDocumentType(
    code: StaffDocumentCode.serviceContract,
    rawCode: 'CP',
    label: 'Contrat de prestation',
    alwaysRequired: false,
    requiredFor: {StaffContractKind.vacataire},
  ),
];
