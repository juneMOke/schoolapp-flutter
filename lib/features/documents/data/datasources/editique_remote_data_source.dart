import 'dart:typed_data';

// `Headers` est déclaré par dio ET par retrofit : ici c'est l'annotation
// retrofit qu'on veut, celle de dio est masquée.
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'editique_remote_data_source.g.dart';

/// Routes d'éditique. Toutes rendent un **corps binaire** (`application/pdf`)
/// et n'ont aucun body de requête.
///
/// `HttpResponse` (et non `Uint8List` nu) parce que le numéro de pièce ne vit
/// que dans l'en-tête `Content-Disposition` : pour un relevé ou un quitus, que
/// le serveur n'archive jamais, c'est la seule occasion de le lire.
///
/// `@DioResponseType(ResponseType.bytes)` est indispensable — sans lui, Dio
/// tenterait de désérialiser le PDF comme du JSON et lèverait sur le premier
/// octet.
///
/// L'en-tête `Accept` **écrase** celui des `BaseOptions` (dio fusionne avec une
/// map insensible à la casse) : il doit donc couvrir le PDF *et* le JSON du
/// corps d'erreur, d'où [AppConstants.pdfAcceptHeader] plutôt que
/// [AppConstants.pdfContentType]. Voir la documentation de cette constante.
@RestApi()
abstract class EditiqueRemoteDataSource {
  factory EditiqueRemoteDataSource(Dio dio, {String baseUrl}) =
      _EditiqueRemoteDataSource;

  @POST(AppConstants.emitEnrollmentAttestationEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitEnrollmentAttestation(
    @Extras() Map<String, dynamic> extras,
    @Path('enrollmentId') String enrollmentId,
  );

  @POST(AppConstants.emitNotePerceptionEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitNotePerception(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('academicYearId') String academicYearId,
  );

  @POST(AppConstants.emitPaymentReceiptEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitPaymentReceipt(
    @Extras() Map<String, dynamic> extras,
    @Path('paymentId') String paymentId,
  );

  @POST(AppConstants.emitAccountStatementEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitAccountStatement(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('academicYearId') String academicYearId,
  );

  @POST(AppConstants.emitFinancialClearanceEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitFinancialClearance(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('academicYearId') String academicYearId,
  );
}
