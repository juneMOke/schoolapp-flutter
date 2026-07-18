import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_ack.dart';

part 'classroom_transfer_sync_api.g.dart';

/// Client de push de l'événement de transfert (CF4, régime A). Idempotent sur
/// `transfer.id` : `201` (créé) et `200` (rejeu) portent la même réponse
/// canonique (appartenance + compteurs des 2 classes recalculés).
@RestApi()
abstract class ClassroomTransferSyncApi {
  factory ClassroomTransferSyncApi(Dio dio, {String baseUrl}) =
      _ClassroomTransferSyncApi;

  /// POST du transfert. `body` = corps figé de l'outbox (`{transfer: {...}}`).
  @POST(AppConstants.syncClassroomTransfersEndpoint)
  Future<ClassroomTransferAck> submitTransfer(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );
}
