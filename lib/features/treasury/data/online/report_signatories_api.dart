import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/treasury/data/wire/report_signatories_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';

/// Les signataires des rapports de caisse, sur Dio : en ligne seulement, sans
/// flux de synchronisation.
class ReportSignatoriesApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const ReportSignatoriesApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<ReportSignatories> fetch() async {
    final response = await _dio.get<Object?>(
      AppConstants.treasuryReportSignatoriesEndpoint,
      options: _options,
    );
    return ReportSignatoriesWire.fromJson(response.data);
  }

  /// Remplace toute la liste. Un rejeu du même corps répond 200 sans rien
  /// écrire ; une liste vide revient aux défauts.
  Future<ReportSignatories> replace({
    required String? expectedUpdatedAt,
    required List<ReportSignatory> signatories,
  }) async {
    final response = await _dio.put<Object?>(
      AppConstants.treasuryReportSignatoriesEndpoint,
      data: ReportSignatoriesWire.putBody(
        expectedUpdatedAt: expectedUpdatedAt,
        signatories: signatories,
      ),
      options: _options,
    );
    return ReportSignatoriesWire.fromJson(response.data);
  }
}
