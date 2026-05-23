import 'package:school_app_flutter/l10n/app_localizations.dart';

extension StudentChargeFeeCodeL10nX on String {
  String localizedFeeLabel(AppLocalizations l10n) => switch (toUpperCase()) {
    'TUITION' => l10n.studentChargeFeeCodeTuition,
    'REGISTRATION' => l10n.studentChargeFeeCodeRegistration,
    'ENROLLMENT' => l10n.studentChargeFeeCodeEnrollment,
    'APPLICATION' => l10n.studentChargeFeeCodeApplication,
    'ADMISSION' => l10n.studentChargeFeeCodeAdmission,
    'CANTEEN' => l10n.studentChargeFeeCodeCanteen,
    'TRANSPORT' => l10n.studentChargeFeeCodeTransport,
    'BOARDING' => l10n.studentChargeFeeCodeBoarding,
    'BOOKS' => l10n.studentChargeFeeCodeBooks,
    'UNIFORM' => l10n.studentChargeFeeCodeUniform,
    'EXAMINATION' => l10n.studentChargeFeeCodeExamination,
    'LAB_FEE' => l10n.studentChargeFeeCodeLabFee,
    'ACTIVITY' => l10n.studentChargeFeeCodeActivity,
    'SPORTS' => l10n.studentChargeFeeCodeSports,
    'LIBRARY' => l10n.studentChargeFeeCodeLibrary,
    'TECHNOLOGY' => l10n.studentChargeFeeCodeTechnology,
    'DEVELOPMENT' => l10n.studentChargeFeeCodeDevelopment,
    'INSURANCE' => l10n.studentChargeFeeCodeInsurance,
    'SECURITY_DEPOSIT' => l10n.studentChargeFeeCodeSecurityDeposit,
    'PROCESSING_FEE' => l10n.studentChargeFeeCodeProcessingFee,
    'LATE_PAYMENT_FEE' => l10n.studentChargeFeeCodeLatePaymentFee,
    'REFUND' => l10n.studentChargeFeeCodeRefund,
    'OTHER' => l10n.studentChargeFeeCodeOther,
    _ => l10n.studentChargeFeeCodeFallback,
  };
}
