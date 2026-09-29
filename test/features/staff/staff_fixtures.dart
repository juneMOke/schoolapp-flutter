/// Lignes de fil du fichier du personnel, telles que le serveur les sert.
Map<String, dynamic> staffMemberJson(
  String id, {
  String lastName = 'Kalala',
  String firstName = 'Jean-Pierre',
  String? staffNumber = 'CF-AG-0001',
  String category = 'ENSEIGNANT',
  List<Map<String, dynamic>> contracts = const [],
  String clientUpdatedAt = '2026-09-29T08:00:00Z',
}) => {
  'id': id,
  'staffNumber': staffNumber,
  'lastName': lastName,
  'middleName': 'Mutombo',
  'firstName': firstName,
  'sex': 'M',
  'birthDate': '1985-04-12',
  'phoneNumber': '+243815566990',
  'email': null,
  'city': 'Kinshasa',
  'district': 'Funa',
  'municipality': 'Kalamu',
  'neighborhood': 'Matonge',
  'address': null,
  'category': category,
  'jobTitle': 'Enseignant titulaire',
  'entryDate': '2019-09-02',
  'branches': ['Mathématiques'],
  'diplomas': [
    {'level': 'Licence', 'title': 'Licence en mathématiques'},
  ],
  'contracts': contracts,
  'clientUpdatedAt': clientUpdatedAt,
  'version': 1,
  'serverUpdatedAt': '2026-09-29T08:00:01Z',
};

Map<String, dynamic> contractPeriodJson(
  String id, {
  String kind = 'PERMANENT',
  String? payMode,
  String effectiveFrom = '2025-09-01',
  String? endsOn,
}) => {
  'contractId': id,
  'kind': kind,
  'payMode': payMode,
  'effectiveFrom': effectiveFrom,
  'endsOn': endsOn,
};

Map<String, dynamic> staffContractJson(
  String id, {
  String staffMemberId = 'm-1',
  String kind = 'PERMANENT',
  int? amountInCents = 32000,
  String? currency = 'usd',
}) => {
  'id': id,
  'staffMemberId': staffMemberId,
  'kind': kind,
  'payMode': null,
  'effectiveFrom': '2025-09-01',
  'endsOn': null,
  'amountInCents': amountInCents,
  'currency': currency,
  'secopeNumber': null,
  'bonusInCents': null,
  'bonusCurrency': null,
  'recordedAt': '2025-09-01T08:00:00Z',
  'correctedAt': null,
  'version': 1,
  'serverUpdatedAt': '2026-09-29T08:00:01Z',
};

Map<String, dynamic> staffDocumentJson(
  String id, {
  String staffMemberId = 'm-1',
  String code = 'ID',
  String capturedAt = '2026-07-04T10:00:00Z',
}) => {
  'id': id,
  'staffMemberId': staffMemberId,
  'code': code,
  'source': 'SCAN',
  'capturedAt': capturedAt,
  'fileName': null,
  'mimeType': 'image/jpeg',
  'sizeBytes': 120000,
  'sha256': 'AB' * 32,
  'version': 1,
  'serverUpdatedAt': '2026-09-29T08:00:01Z',
};
