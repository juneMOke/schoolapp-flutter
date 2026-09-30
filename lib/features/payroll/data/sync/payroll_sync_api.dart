import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/payroll/data/sync/attendance_summary_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/salary_advance_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/staff_pay_profile_dto.dart';

part 'payroll_sync_api.g.dart';

/// Les routes de synchronisation de la Paie.
///
/// **Un envoi par requête** — l'issue d'une écriture est le statut HTTP de sa
/// réponse, et son refus se lit dans le `detailCode`. Les réponses d'écriture
/// restent brutes (`dynamic`) : chaque handler relit ce dont il a besoin, et
/// une forme inattendue ne fait pas échouer un envoi déjà enregistré.
@RestApi()
abstract class PayrollSyncApi {
  factory PayrollSyncApi(Dio dio, {String baseUrl}) = _PayrollSyncApi;

  @PUT(AppConstants.syncPayrollSettingsEndpoint)
  Future<dynamic> putSettings(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncStaffPayProfilesEndpoint)
  Future<dynamic> submitProfile(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncPayrollVariablesEndpoint)
  Future<dynamic> submitVariables(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  /// Rend la paie telle que le geste l'a laissée.
  @POST(AppConstants.syncPayrollGesturesEndpoint)
  Future<PayrollDto> submitGesture(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncSalaryAdvancesEndpoint)
  Future<dynamic> submitAdvance(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncSalaryAdvanceCancellationsEndpoint)
  Future<dynamic> cancelAdvance(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncPayrollDisbursementsEndpoint)
  Future<dynamic> submitDisbursement(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppConstants.syncPayrollDisbursementCancellationsEndpoint)
  Future<dynamic> cancelDisbursement(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @GET(AppConstants.syncPayrollsEndpoint)
  Future<HttpResponse<PayrollPageDto>> pullPayrolls(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncStaffPayProfilesEndpoint)
  Future<HttpResponse<StaffPayProfilePageDto>> pullProfiles(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncStaffAttendanceSummariesEndpoint)
  Future<HttpResponse<AttendanceSummaryPageDto>> pullSummaries(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncSalaryAdvancesEndpoint)
  Future<HttpResponse<SalaryAdvancePageDto>> pullAdvances(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncPayrollDisbursementsEndpoint)
  Future<HttpResponse<PayrollDisbursementPageDto>> pullDisbursements(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
