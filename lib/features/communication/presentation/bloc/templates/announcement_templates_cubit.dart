import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';

enum TemplatesStatus { loading, ready, failure }

class AnnouncementTemplatesState extends Equatable {
  final TemplatesStatus status;
  final List<AnnouncementTemplate> items;
  final Failure? failure;

  const AnnouncementTemplatesState({
    this.status = TemplatesStatus.loading,
    this.items = const [],
    this.failure,
  });

  @override
  List<Object?> get props => [status, items, failure];
}

/// Les modèles de l'école. Chaque écriture rend son échec (ou `null`) : c'est
/// l'écran qui le dit, dans un toast ou sous le formulaire.
class AnnouncementTemplatesCubit extends Cubit<AnnouncementTemplatesState> {
  final AnnouncementTemplateRepository _repository;

  AnnouncementTemplatesCubit(this._repository)
    : super(const AnnouncementTemplatesState());

  Future<void> load() async {
    emit(const AnnouncementTemplatesState());
    final result = await _repository.list();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => AnnouncementTemplatesState(
          status: TemplatesStatus.failure,
          failure: failure,
        ),
        (items) => AnnouncementTemplatesState(
          status: TemplatesStatus.ready,
          items: items,
        ),
      ),
    );
  }

  Future<Failure?> create({
    required AnnouncementCategory category,
    required String title,
    required String body,
  }) async {
    final result = await _repository.create(
      category: category,
      title: title,
      body: body,
    );
    return result.fold((failure) => failure, (template) {
      _replace(template, prepend: true);
      return null;
    });
  }

  Future<Failure?> update(AnnouncementTemplate template) async {
    final result = await _repository.update(template);
    return result.fold((failure) => failure, (saved) {
      _replace(saved);
      return null;
    });
  }

  Future<Failure?> delete(String id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure, (_) {
      if (!isClosed) {
        emit(
          AnnouncementTemplatesState(
            status: state.status,
            items: [
              for (final t in state.items)
                if (t.id != id) t,
            ],
          ),
        );
      }
      return null;
    });
  }

  void _replace(AnnouncementTemplate template, {bool prepend = false}) {
    if (isClosed) return;
    final others = [
      for (final t in state.items)
        if (t.id != template.id) t,
    ];
    final exists = others.length != state.items.length;
    emit(
      AnnouncementTemplatesState(
        status: state.status,
        items: prepend && !exists
            ? [template, ...others]
            : [
                for (final t in state.items)
                  if (t.id == template.id) template else t,
              ],
      ),
    );
  }
}
