/// Les réponses des statistiques de présence, au format exact des DTO du
/// back (`feat/hr-attendance-stats`, 2026-10-24, revue `f8de0fc8` comprise).
library;

Map<String, dynamic> identity({
  String id = 'a-1',
  String payMode = 'FORFAIT_MENSUEL',
}) => {
  'staffMemberId': id,
  'staffNumber': 'CF-AG-0012',
  'lastName': 'MWAMBA',
  'middleName': 'ILUNGA',
  'firstName': 'Clarisse',
  'jobTitle': 'Secrétaire',
  'category': 'ADMINISTRATIF',
  'contractKind': 'PERMANENT',
  'payMode': payMode,
};

Map<String, dynamic> kpis({int? presenceRatePct = 78}) => {
  'scored': 9,
  'presences': 7,
  'presenceRatePct': presenceRatePct,
  'absenceRatePct': presenceRatePct == null ? null : 100 - presenceRatePct,
  'late': 2,
  'lateRatePct': 22,
  'lateMinutes': 31,
  'punctualityPct': 71,
  'justifiedAbsences': 1,
  'unjustifiedAbsences': 3,
  'unscored': 1,
  'workedMinutes': 0,
};

Map<String, dynamic> dashboard() => {
  'from': '2026-10-01',
  'to': '2026-10-23',
  'classDays': 17,
  'staffCount': 14,
  'granularity': 'DAY',
  'kpis': kpis(presenceRatePct: 91),
  'series': [
    {
      'key': '2026-10-22',
      'scored': 14,
      'presences': 13,
      'absences': 1,
      'presenceRatePct': 93,
      'absenceRatePct': 7,
    },
    {
      'key': '2026-10-23',
      'scored': 0,
      'presences': 0,
      'absences': 0,
      'presenceRatePct': null,
      'absenceRatePct': null,
    },
  ],
  // `@JsonUnwrapped` : identité et compteurs à plat.
  'staff': [
    {...identity(), ...kpis()},
    {...identity(id: 'a-2'), ...kpis(presenceRatePct: null)},
  ],
};

Map<String, dynamic> agentMonth() => {
  'month': '2026-10',
  'classDays': 17,
  'toDate': true,
  'agent': identity(),
  'profile': 'ABSENTEISTE',
  'kpis': kpis(),
  'days': [
    {
      'date': '2026-10-01',
      'status': 'RETARD',
      'arrivalTime': '07:52',
      'departureTime': null,
      'lateMinutes': 22,
      'workedMinutes': 0,
      'justificationReason': 'TRANSPORT',
      'justificationNote': 'Embouteillage',
      'future': false,
    },
    {
      'date': '2026-10-02',
      'status': 'PRESENT',
      'arrivalTime': '07:30',
      'departureTime': '15:30',
      'lateMinutes': 0,
      'workedMinutes': 0,
      'justificationReason': null,
      'justificationNote': null,
      'future': false,
    },
    {
      'date': '2026-10-26',
      'status': 'NONE',
      'arrivalTime': null,
      'departureTime': null,
      'lateMinutes': 0,
      'workedMinutes': 0,
      'justificationReason': null,
      'justificationNote': null,
      'future': true,
    },
  ],
  'trend': [
    {'month': '2026-09', 'presenceRatePct': 95},
    {'month': '2026-10', 'presenceRatePct': 78},
  ],
};

Map<String, dynamic> schoolYear() => {
  'name': '2026-2027',
  'from': '2026-09-07',
  'to': '2027-07-02',
};

/// [withYear] faux : l'école est entre deux années, le serveur rend
/// `schoolYear: null`, sans mois.
Map<String, dynamic> agentYear({bool withYear = true}) => {
  'schoolYear': withYear ? schoolYear() : null,
  'agent': identity(),
  'profile': 'REGULIER',
  'kpis': kpis(),
  'months': [
    {
      'month': '2026-09',
      'state': 'CLASS',
      'classDays': 18,
      'scored': 18,
      'presenceRatePct': 95,
      'lateRatePct': 5,
      'absenceRatePct': 5,
      'profile': 'REGULIER',
    },
    {
      'month': '2026-11',
      'state': 'FUTURE',
      'classDays': 0,
      'scored': 0,
      'presenceRatePct': null,
      'lateRatePct': null,
      'absenceRatePct': null,
      'profile': 'NON_EVALUE',
    },
  ],
};

Map<String, dynamic> profiles({String? month = '2026-10'}) => {
  'month': month,
  'schoolYear': month == null ? schoolYear() : null,
  'from': '2026-10-01',
  'to': '2026-10-23',
  'classDays': 17,
  'profileCounts': {
    'EXEMPLAIRE': 5,
    'REGULIER': 5,
    'RETARDATAIRE': 2,
    'ABSENTEISTE': 2,
  },
  'staff': [
    {
      ...identity(),
      'scored': 14,
      'presenceRatePct': 79,
      'lateRatePct': 9,
      'absenceRatePct': 21,
      'profile': 'ABSENTEISTE',
    },
  ],
};

/// Le récapitulatif tel que le sert `feat/payroll-month-m` (L4) ; [legacy] :
/// tel qu'un serveur d'avant le servait.
Map<String, dynamic> recap({bool withAmounts = true, bool legacy = false}) => {
  'month': '2026-10',
  'classDays': 17,
  'toDate': true,
  'closed': false,
  'closedAt': null,
  'closedBy': null,
  'closable': false,
  'unscored': 6,
  if (!legacy) ...{
    'reopenable': false,
    'absenceDeductionEnabled': true,
    'workingDays': 22,
    'payrollStatus': 'DRAFT',
  },
  'totals': {
    'presenceRatePct': 92,
    'workedMinutes': 2760,
    'unjustifiedAbsences': 11,
    'amounts': withAmounts
        ? [
            {
              'currency': 'USD',
              'amountInCents': 36800,
              if (!legacy) ...{
                'baseInCents': 16000,
                'grossInCents': 16000,
                'absenceDeductionInCents': 0,
                'grossAfterAbsenceInCents': 16000,
              },
            },
          ]
        : null,
  },
  'staff': [
    {
      ...identity(payMode: 'HEURES_PRESTEES'),
      'classDays': 17,
      'presences': 10,
      'late': 1,
      'lateMinutes': 12,
      'justifiedAbsences': 0,
      'unjustifiedAbsences': 1,
      'unscored': 0,
      'workedMinutes': 1200,
      'amount': withAmounts
          ? {'currency': 'USD', 'amountInCents': 16000}
          : null,
      if (!legacy) ...{
        'currency': withAmounts ? 'USD' : null,
        'baseInCents': withAmounts ? 16000 : null,
        'grossInCents': withAmounts ? 16000 : null,
        'dailyRateInCents': null,
        'absenceDeductionInCents': null,
        'grossAfterAbsenceInCents': withAmounts ? 16000 : null,
        'hourlyRateInCents': withAmounts ? 800 : null,
      },
    },
  ],
};
