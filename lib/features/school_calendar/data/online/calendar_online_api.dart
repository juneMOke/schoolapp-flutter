import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/documents/data/utils/pdf_response_reader.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_refusal.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';

/// Une année qu'on peut créer, et l'état de son cadre (A5).
class CreatableYear {
  final String yearLabel;
  final FrameworkState framework;

  const CreatableYear(this.yearLabel, this.framework);
}

/// Les seuls gestes **en ligne** du calendrier (A18) : créer, dupliquer,
/// publier — la liste des années créables, et le document du ministère.
/// Tout le reste passe par le lot.
class CalendarOnlineApi {
  final Dio _dio;
  final Map<String, dynamic> _requiredAuth;

  const CalendarOnlineApi(this._dio, this._requiredAuth);

  Options get _options => Options(extra: _requiredAuth);

  Future<Either<Failure, List<CreatableYear>>> creatableYears() =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          AppConstants.calendarCalendarsEndpoint,
          options: _options,
        );
        final raw = response.data?['creatableYears'] as List? ?? const [];
        return [
          for (final year in raw)
            if (year is Map && year['yearLabel'] is String)
              CreatableYear(
                year['yearLabel'] as String,
                FrameworkState.fromWire(year['framework'] as String?),
              ),
        ];
      });

  /// Rejouable : le même [id] rend le même brouillon.
  Future<Either<Failure, SchoolCalendar>> create({
    required String id,
    required String yearLabel,
  }) => _calendar(
    () => _dio.post<Map<String, dynamic>>(
      AppConstants.calendarCalendarsEndpoint,
      data: {'id': id, 'yearLabel': yearLabel},
      options: _options,
    ),
  );

  /// Rejouable par [targetId].
  Future<Either<Failure, SchoolCalendar>> duplicate({
    required String sourceId,
    required String targetId,
    required List<CalendarNature> natures,
  }) => _calendar(
    () => _dio.post<Map<String, dynamic>>(
      AppConstants.calendarDuplicateEndpoint(sourceId),
      data: {
        'targetId': targetId,
        'natures': [for (final n in natures) n.wire],
      },
      options: _options,
    ),
  );

  /// Un calendrier déjà publié répond 200 sans rien refaire (double appui).
  /// La réponse porte l'en-tête sous `calendar`, et les périodes changées.
  Future<Either<Failure, SchoolCalendar>> publish({
    required String id,
    required int revision,
  }) => _calendar(
    () => _dio.post<Map<String, dynamic>>(
      AppConstants.calendarPublishEndpoint(id),
      data: {'revision': revision},
      options: _options,
    ),
    key: 'calendar',
  );

  /// Le document officiel du ministère pour [yearLabel], tel que servi.
  Future<Either<Failure, PrintableDocument>> frameworkDocument(
    String yearLabel,
  ) async {
    try {
      final response = await _dio.get<List<int>>(
        AppConstants.calendarFrameworkDocumentEndpoint(yearLabel),
        options: Options(
          extra: _requiredAuth,
          responseType: ResponseType.bytes,
          headers: {'Accept': AppConstants.pdfAcceptHeader},
          receiveTimeout: AppConstants.timetablePdfTimeout,
        ),
      );
      return PdfResponseReader.read(
        response,
        fallbackFileName: 'calendrier-scolaire-$yearLabel.pdf',
      );
    } on DioException catch (e) {
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  Future<Either<Failure, SchoolCalendar>> _calendar(
    Future<Response<Map<String, dynamic>>> Function() call, {
    String? key,
  }) => _guard(() async {
    final body = (await call()).data ?? const <String, dynamic>{};
    return CalendarWire.calendarFromJson(key == null ? body : body[key]).value;
  });

  /// Un refus métier par son `detailCode`, sinon la traduction commune.
  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on DioException catch (e) {
      final refusal = CalendarRefusal.fromDetailCode(
        ApiErrorParser.detailCodeOf(e.response),
      );
      if (refusal != null) return Left(CalendarRefusalFailure(refusal));
      return guardOnline<T>(() => Future.error(e));
    } catch (e) {
      return guardOnline<T>(() => Future.error(e));
    }
  }
}
