import 'dart:typed_data';

// `Headers` est déclaré par dio ET par retrofit : c'est l'annotation retrofit
// qu'on veut.
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'payslip_api.g.dart';

/// Les bulletins de paie scellés (type éditique BP). Des `GET` : scellés au
/// premier appel, relus ensuite à l'identique — ils se rejouent librement.
@RestApi()
abstract class PayslipApi {
  factory PayslipApi(Dio dio, {String baseUrl}) = _PayslipApi;

  @GET(AppConstants.payrollPayslipEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> payslip(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
    @Path('staffMemberId') String staffMemberId,
  );

  @GET(AppConstants.payrollPayslipPreviewEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> payslipPreview(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
    @Path('staffMemberId') String staffMemberId,
  );

  @GET(AppConstants.payrollMonthPayslipsEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> monthPayslips(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
  );

  @GET(AppConstants.payrollStatementEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> statement(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
  );

  @GET(AppConstants.payrollDashboardPdfEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> dashboard(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
    @Query('filter') String filter,
    @Query('q') String? query,
  );
}
