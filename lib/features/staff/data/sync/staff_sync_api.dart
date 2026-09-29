import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';

part 'staff_sync_api.g.dart';

/// Les routes de synchronisation du fichier du personnel.
///
/// Trois descentes, trois droits : la fiche (`hr.staff.read`), les contrats
/// avec montants (`hr.pay.read`), les métadonnées des pièces
/// (`hr.document.read`). Le plan de synchronisation n'annonce que ce que le
/// compte a le droit de lire.
@RestApi()
abstract class StaffSyncApi {
  factory StaffSyncApi(Dio dio, {String baseUrl}) = _StaffSyncApi;

  /// Remontée d'une fiche entière (idempotente, dernier écrit gagne). Le
  /// corps est le payload figé de l'outbox, relu tel quel.
  @POST(AppConstants.syncStaffMembersEndpoint)
  Future<StaffMemberSyncResponseDto> submitStaffMember(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  /// Pose d'une période datée (ajout seul, `hr.pay.write`).
  @POST(AppConstants.syncStaffContractsOfMemberEndpoint)
  Future<StaffContractSyncResponseDto> submitStaffContract(
    @Extras() Map<String, dynamic> extras,
    @Path('staffMemberId') String staffMemberId,
    @Body() Map<String, dynamic> body,
  );

  /// Correction d'une période saisie par erreur.
  @POST(AppConstants.syncStaffContractCorrectionsEndpoint)
  Future<StaffContractCorrectionResponseDto> correctStaffContract(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @GET(AppConstants.syncStaffMembersEndpoint)
  Future<HttpResponse<StaffMemberPageDto>> pullStaffMembers(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncStaffContractsEndpoint)
  Future<HttpResponse<StaffContractPageDto>> pullStaffContracts(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncStaffDocumentsEndpoint)
  Future<HttpResponse<StaffDocumentPageDto>> pullStaffDocuments(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
