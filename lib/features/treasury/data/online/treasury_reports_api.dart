import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';

/// Les rapports de caisse, sur Dio : la liste, le rapport d'une plage, et le
/// fichier — généré à chaque appel, jamais archivé.
class TreasuryReportsApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const TreasuryReportsApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<CashReportPage> list(CashReportKind kind, int page) async {
    final response = await _dio.get<Object?>(
      AppConstants.treasuryReportsEndpoint,
      queryParameters: {
        'kind': kind.wire,
        'page': page,
        'size': AppConstants.treasuryReportsPageSize,
      },
      options: _options,
    );
    return TreasuryWire.reportPageFromJson(response.data);
  }

  Future<CashReport> period(DateTime from, DateTime to) async {
    final response = await _dio.post<Object?>(
      AppConstants.treasuryReportsEndpoint,
      data: {
        'from': TreasuryWire.dayParam(from),
        'to': TreasuryWire.dayParam(to),
      },
      options: _options,
    );
    return TreasuryWire.reportFromJson(response.data);
  }

  Future<CashReportFile> file(String id, CashReportFormat format) async {
    final response = await _dio.get<List<int>>(
      AppConstants.treasuryReportFileEndpoint.replaceFirst(
        '{reportId}',
        Uri.encodeComponent(id),
      ),
      queryParameters: {'format': format.name},
      options: Options(extra: _extras, responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.isEmpty) {
      throw const FormatException('Le rapport reçu est vide.');
    }
    final fileName = ContentDispositionParser.fileName(
      response.headers.value('content-disposition'),
    );
    return CashReportFile(
      bytes: bytes,
      fileName: fileName ?? '$id.${format.name}',
      format: format,
      status: CashReportStatus.fromWire(
        response.headers.value('x-report-status'),
      ),
    );
  }
}
