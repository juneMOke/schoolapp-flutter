import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/audience_referential_repository.dart';

class AudienceReferentialState extends Equatable {
  final bool loading;
  final AudienceReferential referential;

  /// Une lecture locale ratée : les sélecteurs de classes et de frais disent
  /// qu'ils n'ont rien à proposer, le reste de l'éditeur reste utilisable.
  final bool failed;

  const AudienceReferentialState({
    this.loading = true,
    this.referential = const AudienceReferential(),
    this.failed = false,
  });

  @override
  List<Object?> get props => [loading, referential, failed];
}

/// Les classes et les frais de l'année, lus sur la tablette.
class AudienceReferentialCubit extends Cubit<AudienceReferentialState> {
  final AudienceReferentialRepository _repository;

  AudienceReferentialCubit(this._repository)
    : super(const AudienceReferentialState());

  Future<void> load(String? academicYearId) async {
    if (academicYearId == null) {
      emit(const AudienceReferentialState(loading: false));
      return;
    }
    final result = await _repository.load(academicYearId);
    if (isClosed) return;
    emit(
      result.fold(
        (_) => const AudienceReferentialState(loading: false, failed: true),
        (referential) =>
            AudienceReferentialState(loading: false, referential: referential),
      ),
    );
  }
}
