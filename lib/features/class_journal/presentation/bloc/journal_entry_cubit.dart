import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_prefill.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_entry_use_cases.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// La saisie d'une séance.
///
/// À l'ouverture d'une séance **vierge**, le chapitre en cours est
/// présélectionné et recopié, avec la dernière C.B du cours. Changer de
/// chapitre recopie à nouveau tant que la saisie n'a pas été touchée depuis le
/// dernier préremplissage ; sinon rien n'est écrasé, et « Reprendre du
/// chapitre » le propose.
class JournalEntryCubit extends Cubit<JournalEntryState> {
  final LoadJournalFormSeedUseCase _seed;
  final LoadJournalChapterUseCase _chapter;
  final SaveJournalEntryUseCase _save;
  late JournalSeanceKey _key;

  /// Les champs tels que le dernier préremplissage les a laissés.
  JournalFields _pristine = JournalFields.empty;

  JournalEntryCubit({
    required LoadJournalFormSeedUseCase seed,
    required LoadJournalChapterUseCase chapter,
    required SaveJournalEntryUseCase save,
  }) : _seed = seed,
       _chapter = chapter,
       _save = save,
       super(const JournalEntryState());

  Future<void> open(
    JournalLine line, {
    required DateTime date,
    required Map<String, int> slotOrder,
  }) async {
    _key = line.keyOn(date);
    final seed = await _seed(line.coursId, slotOrder: slotOrder);
    if (isClosed) return;
    final entry = line.entry;
    final known = {for (final c in seed.chapters) c.id};
    if (entry != null && !entry.isBlank) {
      _pristine = entry.fields;
      emit(
        state.copyWith(
          status: JournalEntryStatus.editing,
          chapters: seed.chapters,
          chapitreId: () =>
              known.contains(entry.chapitreId) ? entry.chapitreId : null,
          fields: entry.fields,
          revision: state.revision + 1,
        ),
      );
      return;
    }
    final current = seed.chapters
        .where((c) => c.statut == ChapitreStatut.enCours)
        .firstOrNull;
    final blank = JournalFields(cb: seed.lastCb);
    _pristine = blank;
    emit(
      state.copyWith(
        status: JournalEntryStatus.editing,
        chapters: seed.chapters,
        chapitreId: () => current?.id,
        fields: blank,
        revision: state.revision + 1,
      ),
    );
    if (current != null) await applyChapter();
  }

  void selectChapter(String? chapitreId) {
    if (chapitreId == state.chapitreId) return;
    final pristine = state.fields == _pristine;
    emit(
      state.copyWith(
        chapitreId: () => chapitreId,
        canApplyChapter: chapitreId != null && !pristine,
      ),
    );
    if (chapitreId != null && pristine) unawaited(applyChapter());
  }

  /// Recopie le chapitre choisi : objectif, contenu, stratégie, ressources.
  Future<void> applyChapter() async {
    final chapitreId = state.chapitreId;
    if (chapitreId == null) return;
    final chapitre = await _chapter(chapitreId);
    if (isClosed || chapitre == null || state.chapitreId != chapitreId) return;
    final fields = JournalPrefill.fromChapitre(chapitre, current: state.fields);
    _pristine = fields;
    emit(
      state.copyWith(
        fields: fields,
        revision: state.revision + 1,
        canApplyChapter: false,
      ),
    );
  }

  void updateField(JournalField field, String value) {
    emit(state.copyWith(fields: field.write(state.fields, value)));
  }

  /// Objectif et contenu exigés ; les messages n'apparaissent qu'ici.
  Future<void> save() async {
    if (!state.fields.isFilled) {
      emit(state.copyWith(showErrors: true, refusals: state.refusals + 1));
      return;
    }
    await _write(
      state.fields,
      state.chapitreId,
      done: JournalEntryStatus.saved,
    );
  }

  /// Vide la séance : sept champs vides, sans chapitre — aucune validation.
  Future<void> clear() =>
      _write(JournalFields.empty, null, done: JournalEntryStatus.cleared);

  Future<void> _write(
    JournalFields fields,
    String? chapitreId, {
    required JournalEntryStatus done,
  }) async {
    emit(
      state.copyWith(status: JournalEntryStatus.saving, failure: () => null),
    );
    final result = await _save(_key, fields: fields, chapitreId: chapitreId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: JournalEntryStatus.editing,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: done)),
    );
  }
}
