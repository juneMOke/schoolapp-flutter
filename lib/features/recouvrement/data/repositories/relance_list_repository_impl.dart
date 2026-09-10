import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/data/datasources/relance_list_remote_data_source.dart';
import 'package:school_app_flutter/features/recouvrement/data/mappers/relance_list_mapper.dart';
import 'package:school_app_flutter/features/recouvrement/data/models/relance_list_request_model.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/relance_list_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

class RelanceListRepositoryImpl implements RelanceListRepository {
  final RelanceListRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const RelanceListRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, RelanceList>> emit({
    required RelanceScope scope,
    required List<String> feeCodes,
    required RecouvrementCriterion criterion,
    required List<LocalRecoveryLine> lines,
    required DateTime arretedAt,
    int? thresholdInCents,
    String? thresholdCurrency,
    int? pendingWrites,
  }) async {
    // Le plafond se vérifie ICI, avant le voyage : on connaît le compte, et
    // téléverser un mégaoctet pour se faire refuser serait absurde. Le `400`
    // du serveur reste, mais comme dernier recours.
    if (lines.length > AppConstants.recouvrementRelanceListLineCap) {
      // Le MÊME code et les MÊMES chiffres que le refus du serveur : l'écran
      // n'a qu'un décodeur, et il ne doit pas savoir lequel des deux a refusé.
      return Left(
        ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: ReportLineCap.detailCode,
          details: <String, dynamic>{
            'lines': lines.length,
            'cap': AppConstants.recouvrementRelanceListLineCap,
          },
        ),
      );
    }

    try {
      final body = RelanceListRequestModel.of(
        scope: scope,
        feeCodes: feeCodes,
        criterion: criterion,
        lines: lines,
        arretedAt: arretedAt,
        thresholdInCents: thresholdInCents,
        thresholdCurrency: thresholdCurrency,
        pendingWrites: pendingWrites,
      ).toJson();

      final response = await remoteDataSource.emitRelanceList(
        requiredAuth,
        body,
        Options(
          // ⚠️ **Le délai du client ne convient pas à ce document** : 12 s sont
          // calibrés sur des réponses de guichet, ce rendu prend plusieurs
          // secondes. Expirer de notre côté laisserait le serveur finir un
          // document que personne n'attend, et l'appel suivant se heurterait au
          // 429 d'un rendu cru abandonné.
          receiveTimeout: AppConstants.recouvrementRelanceListTimeout,
          // Le corps monte à 1,6 Mio décompressé au plafond ; gzippé il tient
          // sous 300 Ko. Sur le canal montant d'un guichet, c'est un facteur
          // six — et c'est le seul remède réel, l'intercepteur du serveur ne
          // pouvant refuser qu'APRÈS que les octets sont partis.
          headers: <String, String>{
            Headers.contentEncodingHeader: 'gzip',
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
          requestEncoder: _gzipJson,
        ),
      );
      return RelanceListMapper.map(response);
    } on DioException catch (e) {
      // ⚠️ **Le message du serveur est l'information utile ici**, et
      // l'intercepteur global l'écrase par une constante. Sur le 400 du
      // plafond, c'est lui qui porte le compte réel ; sur `UNKNOWN_STUDENTS`,
      // l'échantillon d'identifiants.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Aucune incertitude à lever : la liste n'est pas archivée et ne
      // consomme rien qu'on ait à réconcilier — un numéro de séquence brûlé
      // n'engage personne. L'échec se réessaie librement.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  /// Compresse le corps JSON avant l'envoi.
  ///
  /// `gzip.encode` plutôt qu'un flux : le corps est déjà tout entier en mémoire
  /// — on vient de le construire — et le streamer n'économiserait rien tout en
  /// compliquant la mesure de sa taille.
  static List<int> _gzipJson(String request, RequestOptions options) =>
      gzip.encode(utf8.encode(request));
}
