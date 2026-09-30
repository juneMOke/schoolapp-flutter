import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payslip_api.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';

/// Les bulletins scellés, en ligne ; les échecs se lisent comme ceux de
/// l'éditique (réseau / 401 / 403 / 422 / 500).
class PayslipRepositoryImpl implements PayslipRepository {
  final PayslipApi _api;
  final Map<String, dynamic> _extras;

  const PayslipRepositoryImpl({
    required PayslipApi api,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _extras = extras;

  @override
  Future<Either<Failure, Uint8List>> payslip(
    String month,
    String staffMemberId,
  ) => _fetch(() => _api.payslip(_extras, month, staffMemberId));

  @override
  Future<Either<Failure, Uint8List>> payslips(String month) =>
      _fetch(() => _api.payslips(_extras, month));

  Future<Either<Failure, Uint8List>> _fetch(
    Future<HttpResponse<Uint8List>> Function() call,
  ) async {
    try {
      final bytes = (await call()).data;
      if (bytes.isEmpty) return const Left(ServerFailure('Bulletin vide'));
      return Right(bytes);
    } on DioException catch (e) {
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
